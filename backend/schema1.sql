CREATE DATABASE IF NOT EXISTS vision_attendance;
USE vision_attendance;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  full_name_ar VARCHAR(150) NULL,
  full_name_en VARCHAR(150) NOT NULL,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30) NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','manager','employee','student') NOT NULL DEFAULT 'employee',
  department VARCHAR(100) NULL,
  employee_id VARCHAR(50) NULL,
  national_id VARCHAR(50) NULL,
  gender ENUM('male','female') NULL,
  date_of_birth DATE NULL,
  photo_url TEXT NULL,
  face_person_id VARCHAR(100) NULL,
  is_face_enrolled TINYINT(1) NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  subscription_plan ENUM('Free','Basic','Standard','Premium') NOT NULL DEFAULT 'Free',
  org_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS settings (
  id INT PRIMARY KEY,
  face_recognition_threshold DECIMAL(4,2) NOT NULL DEFAULT 0.60
);
INSERT INTO settings (id, face_recognition_threshold)
VALUES (1, 0.60)
ON DUPLICATE KEY UPDATE face_recognition_threshold = VALUES(face_recognition_threshold);

CREATE TABLE IF NOT EXISTS attendance (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  room_id INT NULL,
  method VARCHAR(30) NOT NULL DEFAULT 'face',
  checkin_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  checkout_time DATETIME NULL,
  ai_matched TINYINT(1) NOT NULL DEFAULT 0,
  ai_similarity DECIMAL(5,4) NULL,
  ai_spoof_passed TINYINT(1) NULL,
  ai_liveness_ok TINYINT(1) NULL,
  ai_fraud_risk DECIMAL(5,4) NULL,
  ai_quality_grade VARCHAR(20) NULL,
  status ENUM('present','late','absent') NOT NULL DEFAULT 'present',
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (room_id)  REFERENCES rooms(id)
);

CREATE TABLE IF NOT EXISTS vacation_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  days_count INT NOT NULL,
  reason TEXT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  reviewed_by INT NULL,
  reviewed_at DATETIME NULL,
  review_notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS rooms (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  description VARCHAR(255)  NULL,
  capacity    INT           NOT NULL DEFAULT 1,
  room_code   VARCHAR(20)   NOT NULL UNIQUE COMMENT 'Short unique code e.g. RM-001',
  qr_token    VARCHAR(64)   NOT NULL UNIQUE COMMENT 'UUID used in QR for check-in',
  latitude    DOUBLE        NULL,
  longitude   DOUBLE        NULL,
  is_active   TINYINT(1)    NOT NULL DEFAULT 1,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_locations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  captured_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
