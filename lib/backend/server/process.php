<?php


$getAction = [
    'getRole' => 'getColumnValueUsers',
    'getStatus' => 'getColumnValueUsers',
    'getInvite' => 'getColumnValueUsers',
    'getAccountAge' => 'getColumnValueUsers',
    'getRoom' => 'getColumnValueUsers',
    'getUsers' => 'getUsers',
    'getId' => 'getColumnValueUsers',
    'getFcm' => 'getColumnValueUsers',
];

$getActionRooms = [
    'getRoomId' => 'getColumnValueRooms',
    'getRoomCode' => 'getColumnValueRooms',
    'getOwnerId' => 'getColumnValueRooms',
    'getAudioPath' => 'getColumnValueRooms',
    'getDuration' => 'getColumnValueRooms',
    'getTitle' => 'getColumnValueRooms',
    'getBody' => 'getColumnValueRooms',
    'getLoopAudio' => 'getColumnValueRooms',
    'getVibrate' => 'getColumnValueRooms',
    'getVolume' => 'getColumnValueRooms',
    'getFadeDuration' => 'getColumnValueRooms',
    'getFullScreenIntent' => 'getColumnValueRooms',
    'getEnforceVolume' => 'getColumnValueRooms',
    'getCreatedAt' => 'getColumnValueRooms',
];

$changeActionRooms = [
    'changeOwnerId' => 'updateRoomsInformation',
    'changeAudioPath' => 'updateRoomsInformation',
    'changeDuration' => 'updateRoomsInformation',
    'changeTitle' => 'updateRoomsInformation',
    'changeBody' => 'updateRoomsInformation',
    'changeLoopAudio' => 'updateRoomsInformation',
    'changeVibrate' => 'updateRoomsInformation',
    'changeVolume' => 'updateRoomsInformation',
    'changeFadeDuration' => 'updateRoomsInformation',
    'changeFullScreenIntent' => 'updateRoomsInformation',
    'changeEnforceVolume' => 'updateRoomsInformation',
];


$changeAction = [
    'changeInvite' => 'processRoom',
    'changeRoom' => 'processRoom',
    'changeRole' => 'processRoom',
    'changeFcm' => 'processRoom',
    'getUsers' => 'getUsers',
];

$soundAlarm = [
    'singleAlarm' => 'soundSingleAlarm'
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Load config if available, otherwise use defaults
    if (file_exists('config.php')) {
        require_once 'config.php';
    } else {
        // Fallback to default values if config.php doesn't exist
        define('DB_HOST', 'localhost');
        define('DB_NAME', 'schweis_rescuesync');
        define('DB_USER', 'root');
        define('DB_PASS', '');
    }
    
    require_once 'rescuesync.php';

    $rescuesync = new RescueSync(DB_HOST, DB_NAME, DB_USER, DB_PASS);

    $action = $_POST['action'] ?? '';

    header('Content-Type: application/json'); // JSON formatında yanıt döndür

    if ($action === 'register') {
        $username = htmlspecialchars(trim($_POST['username'] ?? ''));
        $email = htmlspecialchars(trim($_POST['email'] ?? ''));
        $password = htmlspecialchars(trim($_POST['password'] ?? ''));
        $fcmToken = htmlspecialchars(trim($_POST['fcmToken'] ?? ''));

        // Giriş doğrulaması
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            echo json_encode(['status' => 'error', 'data' => 'Invalid email format.']);
            exit;
        }
        if (strlen($username) < 3 || strlen($username) > 20) {
            echo json_encode(['status' => 'error', 'data' => 'Username must be between 3 and 20 characters.']);
            exit;
        }
        if (strlen($password) < 6) {
            echo json_encode(['status' => 'error', 'data' => 'Password must be at least 6 characters long.']);
            exit;
        }

        // Generate random 9-digit invite code
        $invite = str_pad(rand(0, 999999999), 9, '0', STR_PAD_LEFT);

        $result = $rescuesync->register($username, $email, $password, $invite, $fcmToken);
        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    } else if ($action === 'login') {
        $username = htmlspecialchars(trim($_POST['username'] ?? ''));
        $password = htmlspecialchars(trim($_POST['password'] ?? ''));
        $fcmToken = htmlspecialchars(trim($_POST['fcmToken'] ?? ''));

        $result = $rescuesync->login($username, $password, $fcmToken);
        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    } else  if ($action == 'singleAlarm') {
        $username = $_POST['username'] ?? null;
        $time = $_POST['time'] ?? '30';
        $callUser = $_POST['callUser'] ?? null;
        $dateTime = $_POST['dateTime'] ?? 'now';
        if (empty($username) || empty($time) || empty($callUser) || empty($dateTime)) {
            echo json_encode(['status' => 'error', 'data' => 'Tüm parametreler girilmek zorunda!']);
        }
        $result = $rescuesync->soundSingleAlarm($username, $time, $callUser, $dateTime);
        if ($result === null) {
            echo json_encode(['status' => 'error', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    } else if (array_key_exists($action, $getAction)) {

        // Sütun ismi action'a göre belirleniyor
        $column = match ($action) {
            'getRole' => 'role',
            'getStatus' => 'status',
            'getInvite' => 'invite',
            'getAccountAge' => 'created_at',
            'getRoom' => 'room',
            'getId' => 'id',
            'getUsers' => 'users',
            'getFcm' => 'fcmToken',
            default => null,
        };

        // Kullanıcı adı kontrolü
        $username = $_POST['username'] ?? null;
        if (!$username) {
            echo json_encode(['status' => 'error', 'data' => 'Username is required.']);
            exit;
        }

        if ($action === 'getUsers') {
            $room = $_POST['room'] ?? null;
            if (!$room) {
                echo json_encode(['status' => 'error', 'data' => 'Oda bilgisi gerekli']);
                exit;
            }
            $result = $rescuesync->getUsers($room);
            if (is_array($result) && !empty($result)) {
                if ($result === null) {
                    echo json_encode(['status' => 'success', 'data' => 'null']);
                } else {
                    echo json_encode(['status' => 'success', 'data' => $result]);
                }
            } else {
                echo json_encode(['status' => 'error', 'data' => 'No users found or an error occurred']);
            }
            exit;
        } else {
            $result = $rescuesync->getColumnValueUsers($username, $column);
        }

        // Dinamik fonksiyon çağrısı

        // $result = $rescuesync->getColumnValueUsers($username, $column);
        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    } else if ($action != '' && $action !== null && array_key_exists($action, $getActionRooms)) {

        // Sütun ismine göre action belirleme
        $column = match ($action) {
            'getRoomId' => 'room_id',
            'getRoomCode' => 'roomCode',
            'getOwnerId' => 'ownerId',
            'getAudioPath' => 'audioPath',
            'getDuration' => 'duration',
            'getTitle' => 'title',
            'getBody' => 'body',
            'getLoopAudio' => 'loopAudio',
            'getVibrate' => 'vibrate',
            'getVolume' => 'volume',
            'getFadeDuration' => 'fadeDuration',
            'getFullScreenIntent' => 'fullScreenIntent',
            'getEnforceVolume' => 'enforceVolume',
            'getCreatedAt' => 'created_at',
            default => null,
        };

        // Room code kontrolü
        $room = $_POST['roomCode'] ?? null;
        if (!$room) {
            echo json_encode([
                'status' => 'error',
                'data' => 'Room code is required'
            ]);
        }

        $result = $rescuesync->getColumnValueRooms($room, $column);

        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
        exit;
    } else if ($action != '' && $action !== null && array_key_exists($action, $changeActionRooms)) {
        // Sütun ismine göre action belirleme
        $column = match ($action) {

            'changeOwnerId' => 'ownerId',
            'changeAudioPath' => 'audioPath',
            'changeDuration' => 'duration',
            'changeTitle' => 'title',
            'changeBody' => 'body',
            'changeLoopAudio' => 'loopAudio',
            'changeVibrate' => 'vibrate',
            'changeVolume' => 'volume',
            'changeFadeDuration' => 'fadeDuration',
            'changeFullScreenIntent' => 'fullScreenIntent',
            'changeEnforceVolume' => 'enforceVolume',

            default => null,
        };

        $username = $_POST['username'] ?? null;
        $roomCode = $_POST['roomCode'] ?? null;
        $update = $_POST['update'] ?? null;

        if (!$username || !$roomCode) {
            echo json_encode([
                'status' => 'error',
                'data' => 'Username and Room code is required'
            ]);
        }
        $result = $rescuesync->updateRoomsInformation($username, $roomCode, $update, $column,);

        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
        exit;
    } else if ($action !== '' && $action !== null && array_key_exists($action, $changeAction)) {
        $processType = match ($action) {
            'changeInvite' => 'invite',
            'changeRoom'   => 'room',
            'changeRole'   => 'role',
            'changeFcm' => 'fcmToken',
            'getUsers' => 'users',
            default        => null,
        };

        if (is_null($processType)) {
            echo json_encode(['status' => 'error', 'data' => 'Geçersiz işlem türü.']);
            exit;
        }

        $username = $_POST['username'] ?? null;
        if (!$username) {
            echo json_encode(['status' => 'error', 'data' => 'Kullanıcı adı gerekli']);
            exit;
        }

        $room = $_POST['room'] ?? null;
        if (empty($room)) {
            echo json_encode(['status' => 'error', 'data' => 'Oda bilgisi gerekli']);
            exit;
        }

        // processRoom metodunu çağırırken değişkenleri doğru sırayla gönder
        $result = $rescuesync->processRoom($username, $processType, $room);
        if ($result === null) {
            echo json_encode(['status' => 'success', 'data' => 'None']);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    } else if ($action == 'changeUsername' || $action == 'changePassword' || $action == 'changeMail') {
        $column = match ($action) {
            'changeUsername' => 'username',
            'changePassword' => 'password',
            'changeMail' => 'email',
            default => null,
        };

        $username = $_POST['username'] ?? null;
        $data = $_POST['data'] ?? null;

        if (!$username || !$data) {
            echo json_encode(['status' => 'error', 'data' => 'Username or Data field is missing']);
            exit;
        }

        if (!$column) {
            echo json_encode(['status' => 'error', 'data' => 'Invalid action type']);
            exit;
        }

        $result = $rescuesync->updateAccountInformation($username, $data, $column);
        if (str_contains($result, 'Error')) {
            echo json_encode(['status' => 'error', 'data' => $result]);
        } else {
            echo json_encode(['status' => 'success', 'data' => $result]);
        }
    }
} else {
    echo json_encode(['status' => 'error', 'data' => 'Invalid action.']);
}
