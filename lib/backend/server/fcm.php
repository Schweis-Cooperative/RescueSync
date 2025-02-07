<?php

require 'vendor/autoload.php'; // Firebase PHP SDK'yı yükle

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

// Service Account JSON dosyasını kullanarak Firebase'i başlat
$factory = (new Factory)->withServiceAccount('serviceAccountKey.json'); // service account on firebase
$messaging = $factory->createMessaging();

// Bildirim verileri
$callerName = $_POST['callerName']; // SOS başlatan kullanıcı
$receiverName = $_POST['receiverName']; // SOS alacak kullanıcı
$duration = $_POST['duration']; // Alarm süresi (saniye)
$startTime = $_POST['startTime']; // Alarmın başlama zamanı

// FCM Token (Alıcının cihazının FCM token'ı)
$fcmToken = $_POST['fcmToken'];

// API'den receiverId'yi almak için cURL isteği
$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, "https://api.schweis.eu/rescuesync/process");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
    'action' => 'getId',
    'username' => $receiverName,
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/x-www-form-urlencoded',
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
curl_close($ch);

// JSON yanıtını decode et
$responseData = json_decode($response, true);

// Eğer başarılı bir yanıt alındıysa receiverId'yi al
if (isset($responseData['status']) && $responseData['status'] === 'success') {
    $receiverId = $responseData['data'];
} else {
    // Hata durumunda uygun bir işlem yap
    die("API'den receiverId alınamadı: " . $response);
}

// Bildirim mesajı oluştur
$message = CloudMessage::withTarget('token', $fcmToken)
    ->withNotification(Notification::create(
        'Acil Durum Çağrısı', // Bildirim başlığı
        "$callerName kullanıcısı tarafından çağrılıyorsunuz!" // Bildirim içeriği
    ))
    ->withData([
        'action' => 'SOS',
        'caller' => $callerName,
        'receiver' => $receiverName,
        'receiver_id' => $receiverId,
        'duration' => $duration,
        'start_time' => $startTime,
    ]);

// Bildirimi gönder
try {
    $messaging->send($message);
    echo "Bildirim başarıyla gönderildi!";
} catch (\Exception $e) {
    echo "Bildirim gönderilirken hata oluştu: " . $e->getMessage();
}

?>
