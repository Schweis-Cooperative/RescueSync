CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY, -- User ID, auto-incrementing
    username VARCHAR(50) NOT NULL UNIQUE, -- Username, unique and cannot be empty
    password VARCHAR(255) NOT NULL, -- Password, should be stored hashed for security
    email VARCHAR(100) NOT NULL UNIQUE, -- Email address, unique and cannot be empty
    invite VARCHAR(50) NOT NULL UNIQUE, -- User's invite code (9-digit unique code)
    fcmToken VARCHAR(512) NOT NULL, -- Firebase Cloud Messaging token
    status ENUM('normal', 'banned') DEFAULT 'normal', -- Account status, default is 'normal'
    room VARCHAR(50) DEFAULT NULL, -- Room code the user belongs to (references invite code)
    role ENUM('owner', 'moderator', 'member') DEFAULT NULL, -- User role, initially empty
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Account creation timestamp
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;