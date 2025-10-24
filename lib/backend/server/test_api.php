<?php
/**
 * Simple API Test Script
 * Upload this to your server and access it via browser to test if the API is working
 * URL:
 */

header('Content-Type: application/json');

echo json_encode([
    'status' => 'success',
    'message' => 'API is reachable',
    'php_version' => phpversion(),
    'config_exists' => file_exists('config.php'),
    'rescuesync_exists' => file_exists('rescuesync.php'),
    'process_exists' => file_exists('process.php'),
    'vendor_exists' => file_exists('vendor/autoload.php'),
    'post_method' => $_SERVER['REQUEST_METHOD'] === 'POST',
    'timestamp' => date('Y-m-d H:i:s')
]);
