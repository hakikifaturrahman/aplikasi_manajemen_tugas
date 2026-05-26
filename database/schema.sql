-- MySQL Database Schema for TaskFlow
-- Database: taskflow_db

CREATE DATABASE IF NOT EXISTS taskflow_db;
USE taskflow_db;

-- 1. Table: users
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  profile_picture VARCHAR(1000) DEFAULT NULL,
  remind_deadlines TINYINT(1) DEFAULT 1,
  weekly_report TINYINT(1) DEFAULT 0,
  new_tasks TINYINT(1) DEFAULT 1,
  email_alerts TINYINT(1) DEFAULT 1,
  is_private_profile TINYINT(1) DEFAULT 0,
  enable_two_factor TINYINT(1) DEFAULT 0,
  session_timeout TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Table: categories
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Table: tasks
CREATE TABLE IF NOT EXISTS tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT NULL,
  deadline DATE NOT NULL,
  status ENUM('Pending', 'Progress', 'Done') DEFAULT 'Pending',
  category_id INT NOT NULL,
  user_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Table: support_tickets
CREATE TABLE IF NOT EXISTS support_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  subject VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Table: task_histories
CREATE TABLE IF NOT EXISTS task_histories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  task_id INT DEFAULT NULL,
  task_title VARCHAR(255) NOT NULL,
  action VARCHAR(50) NOT NULL,
  details TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Seed default categories if they do not exist
INSERT INTO categories (category_name)
SELECT * FROM (
  SELECT 'Backend' AS category_name UNION ALL
  SELECT 'Frontend' UNION ALL
  SELECT 'UI/UX' UNION ALL
  SELECT 'Testing' UNION ALL
  SELECT 'Dokumentasi'
) AS default_categories
WHERE NOT EXISTS (
  SELECT 1 FROM categories LIMIT 1
);
