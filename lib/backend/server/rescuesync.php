<?php

class RescueSync
{
    private $pdo;

    public function __construct($host, $dbname, $username, $password)
    {
        try {
            $this->pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
        } catch (PDOException $e) {
            die("Database connection failed: " . $e->getMessage());
        }
    }

    public function register($username, $email, $password, $invite, $fcmToken)
    {
        try {
            // Check if username or email already exists
            $stmt = $this->pdo->prepare("SELECT id FROM users WHERE username = :username OR email = :email");
            $stmt->execute(['username' => $username, 'email' => $email]);

            if ($stmt->rowCount() > 0) {
                return "Username or email already exists.";
            }

            // Hash the password
            $hashedPassword = password_hash($password, PASSWORD_BCRYPT);

            // Insert new user into the database
            $stmt = $this->pdo->prepare(
                "INSERT INTO users (username, password, email, invite, fcmToken) VALUES (:username, :password, :email, :invite, :fcmToken)"
            );

            $stmt->execute([
                'username' => $username,
                'password' => $hashedPassword,
                'email' => $email,
                'invite' => $invite,
                'fcmToken' => $fcmToken
            ]);

            return "Registration successful.";
        } catch (PDOException $e) {
            return "Error: " . $e->getMessage();
        }
    }

    public function login($username, $password, $fcmToken)
    {
        try {
            // Fetch user by username
            $stmt = $this->pdo->prepare("SELECT id, password, status FROM users WHERE username = :username");
            $stmt->execute(['username' => $username]);

            if ($stmt->rowCount() === 0) {
                return "Invalid username or password.";
            }

            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            // Check if the account is banned
            if ($user['status'] === 'banned') {
                return "Account is banned.";
            }

            // Verify the password
            if (password_verify($password, $user['password'])) {
                $stmtUpdate = $this->pdo->prepare('UPDATE users SET fcmToken = :fcmToken WHERE username = :username');
                $stmtUpdate->execute([

                    'fcmToken' => $fcmToken,
                    'username' => $username,
                ]);
                return "Login successful.";
            } else {
                return "Invalid username or password.";
            }
        } catch (PDOException $e) {
            return "Error: " . $e->getMessage();
        }
    }


    public function getColumnValueUsers($username, $column)
    {
        try {
            $allowedColumns = ['id', 'username', 'password', 'email', 'invite', 'fcmToken', 'status', 'room', 'role', 'created_at'];
            if (!in_array($column, $allowedColumns)) {
                throw new Exception("Geçersiz İşlem Türü: $column");
            }

            $stmt = $this->pdo->prepare("SELECT $column FROM users WHERE username = :username");
            $stmt->execute(['username' => $username]);

            if ($stmt->rowCount() === 0) {
                return "User not found.";
            }

            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            // Eğer sütun invite veya role null ise özel bir yanıt döndür
            if ($column === 'invite' && is_null($user['invite'])) {
                return "None";
            }

            if ($column === 'role' && is_null($user['role'])) {
                return "None";
            }

            return $user[$column];
        } catch (Exception $e) {
            return "Error: " . $e->getMessage();
        }
    }

    public function getColumnValueRooms($roomCode, $column)
    {
        try {
            $allowedColumns = [
                'room_id',
                'roomCode',
                'ownerId',
                'audioPath',
                'duration',
                'title',
                'body',
                'loopAudio',
                'vibrate',
                'volume',
                'fadeDuration',
                'fullScreenIntent',
                'enforceVolume',
                'created_at'
            ];
            if (!in_array($column, $allowedColumns)) {
                throw new Exception('Geçersiz işlem türü: ' . $column);
            }

            $room = $roomCode ?? null;
            if (!$room) {
                throw new Exception('Room code is required');
            }

            $stmt = $this->pdo->prepare("SELECT $column FROM rooms WHERE roomCode = :roomCode");
            $stmt->execute([
                'roomCode' => $room
            ]);

            if ($stmt->rowCount() == 0) {
                throw new Exception('Room not found');
            }
            $result = $stmt->fetch(PDO::FETCH_DEFAULT);

            return $result[$column];
        } catch (Exception $e) {
            return 'Error: ' . $e->getMessage();
        }
    }


    public function processRoom($username, $processType, $room)
    {
        try {
            $allowedTypes = ["invite", "room", "role", "fcmToken"];

            if (!in_array($processType, $allowedTypes)) {
                throw new Exception("Geçersiz işlem türü: " . $processType);
            }

            // Önce kullanıcının varlığını kontrol et
            $stmt = $this->pdo->prepare("SELECT * FROM users WHERE username = :username");
            $stmt->execute(['username' => $username]);

            if ($stmt->rowCount() === 0) {
                throw new Exception("Kullanıcı bulunamadı");
            }

            switch ($processType) {
                case 'invite':
                    $newInvite = str_pad(rand(0, 999999999), 9, '0', STR_PAD_LEFT);
                    $updateStmt = $this->pdo->prepare('UPDATE users SET invite = :invite WHERE username = :username');
                    $updateStmt->execute([
                        'invite' => $newInvite,
                        'username' => $username
                    ]);
                    return $newInvite;

                case 'fcmToken':
                    $updateStmt = $this->pdo->prepare('UPDATE users SET fcmToken = :fcmToken WHERE username = :username');
                    $updateStmt->execute([
                        'fcmToken' => $room,
                        'username' => $username,
                    ]);

                    if ($updateStmt->rowCount() > 0) {
                        return 'true';
                    }


                case 'room':
                    // Sadece tek bir kullanıcı (owner) çek
                    $stmt = $this->pdo->prepare('SELECT username, status, id FROM users WHERE invite = :invite AND username != :username');
                    $stmt->execute([
                        'invite' => $room,
                        'username' => $username
                    ]);

                    $owner = $stmt->fetch(PDO::FETCH_ASSOC);

                    // Owner yoksa hata
                    if ($owner === false) {
                        throw new Exception('Geçersiz davet kodu');
                    }

                    // Owner'ın durumu kontrolü
                    if ($owner['status'] !== 'normal') {
                        throw new Exception('Kullanıcı yasaklı');
                    }

                    // Mevcut kullanıcının odasını güncelle
                    $updateStmt = $this->pdo->prepare('UPDATE users SET room = :room WHERE username = :username');
                    $updateStmt->execute([
                        'room' => $room,
                        'username' => $username
                    ]);

                    // Odaya katılan kullanıcının rolünü member yap
                    $updateRole = $this->pdo->prepare('UPDATE users SET role = :role WHERE username = :username');
                    $updateRole->execute([
                        'role' => 'member',
                        'username' => $username
                    ]);

                    // Owner'ın rolünü owner yap ve odasını güncelle
                    $ownerName = $owner['username'];
                    $updateOwnerRole = $this->pdo->prepare('UPDATE users SET role = :role, room = :room WHERE username = :username');
                    $updateOwnerRole->execute([
                        'role' => 'owner',
                        'room' => $room,
                        'username' => $ownerName
                    ]);

                    // Odanın rooms tablosunda olup olmadığını kontrol et

                    $roomsStmt = $this->pdo->prepare('SELECT roomCode FROM rooms WHERE roomCode = :roomCode');
                    $roomsStmt->execute([
                        'roomCode' => $room
                    ]);
                    $check = $roomsStmt->fetch(PDO::FETCH_DEFAULT);
                    if (!$check) {
                        $roomStmt = $this->pdo->prepare(
                            'INSERT INTO rooms (roomCode, ownerId) VALUES (:room, :ownerId)'
                        );
                        $roomStmt->execute([
                            'room' => $room,
                            'ownerId' => $owner['id']
                        ]);
                    }

                    return 'true'; // Başarılı

                case 'role':
                    $updateStmt = $this->pdo->prepare('UPDATE users SET role = :role WHERE username = :username');
                    $updateStmt->execute([
                        'role' => $room,
                        'username' => $username
                    ]);
                    return 'true';

                default:
                    throw new Exception("Geçersiz işlem");
            }
        } catch (Exception $e) {
            return "Hata: " . $e->getMessage();
        }
    }

    public function getUsers($room)
    {
        if (empty($room)) {
            return ['error' => 'Room parameter is required'];
        }
        $stmt = $this->pdo->prepare("SELECT username, role FROM users WHERE room = :room");
        $stmt->execute(['room' => $room]);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $users; // PHP dizi olarak döndür
    }


    public function soundSingleAlarm($username, $time, $callUser, $dateTime)
    {
        if (empty($username) || empty($callUser) || empty($dateTime)) {
            return null;
        }
        $stmt = $this->pdo->prepare('SELECT id FROM users WHERE username = :username');
        $stmt->execute([
            'username' => $callUser
        ]);
        $users = $stmt->fetch(PDO::FETCH_ASSOC);
        $id = $users['id'];
        if (empty($id)) {
            return null;
        }
        $data = [
            'user' => $username,
            'time' => $time,
            'callUser' => $callUser,
            'dateTime' => $dateTime,
            'id' => $id
        ];
        return $data;
    }

    public function updateAccountInformation($username, $update, $column)
    {
        try {
            // İzin verilen işlem türleri
            $allowedTypes = ["username", "password", "email"];

            // Geçerli bir işlem türü kontrolü
            if (!in_array($column, $allowedTypes)) {
                throw new Exception("Geçersiz işlem türü: $column");
            }

            // Şifre değişikliği durumunda hashleme işlemi
            if ($column === 'password') {
                $update = password_hash($update, PASSWORD_BCRYPT);
            }

            // Güncelleme sorgusu
            $stmt = $this->pdo->prepare("UPDATE users SET $column = :updateValue WHERE username = :username");
            $stmt->execute([
                'updateValue' => $update,
                'username' => $username
            ]);

            // Etkilenen satır sayısını kontrol et
            $affectedRows = $stmt->rowCount();
            if ($affectedRows > 0) {
                return $username;
            } else {
                return "Error: No rows affected or username not found";
            }
        } catch (Exception $e) {
            return "Error: {$e->getMessage()}";
        }
    }


    public function updateRoomsInformation($username, $roomCode, $update, $column)
    {
        try {
            $allowedTypes = [
                "ownerId",
                "audioPath",
                "duration",
                "title",
                "body",
                "loopAudio",
                "vibrate",
                "volume",
                "fadeDuration",
                "fullScreenIntent",
                "enforceVolume"
            ];

            $ownerAction = [
                "ownerId",
                "audioPath",
                "loopAudio",
                "vibrate",
                "volume",
                "fadeDuration",
                "fullScreenIntent",
                "enforceVolume"
            ];

            if (!in_array($column, $allowedTypes)) {
                throw new Exception("Geçersiz işlem türü: $column");
            }

            $isOwner = false;
            $stmtUser = $this->pdo->prepare("SELECT id FROM users WHERE username = :username");
            $stmtUser->execute([
                'username' => $username
            ]);
            $userId = $stmtUser->fetch(PDO::FETCH_DEFAULT);
            $userId = $userId['id'];

            $stmtOwner = $this->pdo->prepare("SELECT ownerId FROM rooms WHERE roomCode = :roomCode");
            $stmtOwner->execute([
                'roomCode' => $roomCode
            ]);
            $ownerId = $stmtOwner->fetch(PDO::FETCH_DEFAULT);
            $ownerId = $ownerId['ownerId'];
            if ($ownerId === $userId) {
                $isOwner = true;
            }

            if (!$isOwner && in_array($column, $ownerAction)) {
                throw new Exception("You do not have permission for this operation!");
            } else {
                $stmtUpdate = $this->pdo->prepare("UPDATE rooms SET $column = :updateColumn WHERE roomCode = :roomCode");
                $stmtUpdate->execute([
                    'updateColumn' => $update,
                    'roomCode' => $roomCode,
                ]);

                $affectedRows = $stmtUpdate->rowCount();
                if ($affectedRows > 0) {
                    return 'True';
                } else {
                    return "Error: No rows affected or username not found";
                }
            }
        } catch (Exception $e) {
            return "Error: {$e->getMessage()}";
        }
    }


    public function getHomeScreen($username) {
        // TODO: Implement home screen data fetching
        // This should return user stats, recent activity, etc.
        return null;
    }
}
