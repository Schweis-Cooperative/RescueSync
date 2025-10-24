CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY, -- Room ID, auto-incrementing
    roomCode VARCHAR(50) NOT NULL UNIQUE, -- Room code (invite code that created the room), unique
    ownerId INT NOT NULL, -- Owner's user ID (foreign key to users.id)
    audioPath VARCHAR(255) DEFAULT 'assets/alarm/alarm.mp3', -- Custom alarm sound path
    duration INT DEFAULT 30, -- Alarm duration in seconds
    title VARCHAR(255) DEFAULT 'EMERGENCY CALL', -- Notification title
    body TEXT DEFAULT 'You are being called by user!', -- Notification body text
    loopAudio BOOLEAN DEFAULT FALSE, -- Whether to loop the audio
    vibrate BOOLEAN DEFAULT TRUE, -- Whether to vibrate
    volume DECIMAL(3,2) DEFAULT 1.00, -- Volume level (0.00 to 1.00)
    fadeDuration DECIMAL(4,2) DEFAULT 5.00, -- Fade duration in seconds
    fullScreenIntent BOOLEAN DEFAULT TRUE, -- Full-screen notification intent
    enforceVolume BOOLEAN DEFAULT TRUE, -- Enforce volume level
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Room creation timestamp
    FOREIGN KEY (ownerId) REFERENCES users(id) ON DELETE CASCADE -- Delete room if owner is deleted
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
