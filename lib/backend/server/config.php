<?php

/**
 * Load environment variables from .env file
 * Simple implementation without external dependencies
 */
function loadEnv($path = __DIR__ . '/.env') {
    if (!file_exists($path)) {
        // If .env doesn't exist, use default values or throw error
        return false;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Skip comments
        if (strpos(trim($line), '#') === 0) {
            continue;
        }

        // Parse KEY=VALUE
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            
            // Remove quotes if present
            $value = trim($value, '"\'');
            
            // Set as environment variable
            putenv("$key=$value");
            $_ENV[$key] = $value;
            $_SERVER[$key] = $value;
        }
    }
    
    return true;
}

/**
 * Get environment variable with fallback
 */
function env($key, $default = null) {
    $value = getenv($key);
    if ($value === false) {
        return $default;
    }
    return $value;
}

// Load environment variables
loadEnv();

// Database configuration
define('DB_HOST', env('DB_HOST', 'localhost'));
define('DB_NAME', env('DB_NAME', 'rescuesync'));
define('DB_USER', env('DB_USER', 'root'));
define('DB_PASS', env('DB_PASS', ''));

// API configuration
define('API_URL', env('API_URL', 'https://api.nativez.dev'));

// Firebase configuration
define('FIREBASE_SERVICE_ACCOUNT', env('FIREBASE_SERVICE_ACCOUNT', 'serviceAccountKey.json'));
