<?php
define('DB_PATH', __DIR__ . '/../../database/laundry.db');

function getDB() {
    try {
        $db = new PDO('sqlite:' . DB_PATH);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $db->exec('PRAGMA foreign_keys = ON;');
        return $db;
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Database connection failed: ' . $e->getMessage()]);
        exit;
    }
}

function initDB() {
    $db = getDB();
    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            phone TEXT,
            password TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'customer',
            address TEXT,
            profile_image TEXT,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price_per_item REAL NOT NULL DEFAULT 2.0,
            icon TEXT,
            is_active INTEGER DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            delivery_boy_id INTEGER,
            service_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            pickup_address TEXT NOT NULL,
            delivery_address TEXT NOT NULL,
            total_amount REAL DEFAULT 0,
            color_preference TEXT DEFAULT 'color',
            washing_temp TEXT DEFAULT 'celsius',
            use_dry_heater INTEGER DEFAULT 0,
            use_scented_detergent INTEGER DEFAULT 0,
            use_softener INTEGER DEFAULT 0,
            additional_note TEXT,
            payment_method TEXT DEFAULT 'cash',
            payment_status TEXT DEFAULT 'pending',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (customer_id) REFERENCES users(id),
            FOREIGN KEY (delivery_boy_id) REFERENCES users(id),
            FOREIGN KEY (service_id) REFERENCES services(id)
        );

        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            gender TEXT DEFAULT 'unisex',
            quantity INTEGER DEFAULT 0,
            price REAL DEFAULT 2.0,
            FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            method TEXT DEFAULT 'cash',
            status TEXT DEFAULT 'pending',
            transaction_id TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (order_id) REFERENCES orders(id)
        );

        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
    ");

    // Seed default services
    $count = $db->query("SELECT COUNT(*) FROM services")->fetchColumn();
    if ($count == 0) {
        $db->exec("
            INSERT INTO services (name, description, price_per_item, icon) VALUES
            ('Wash & Iron', 'Full wash and iron service', 2.0, 'wash_iron'),
            ('Ironing', 'Ironing only service', 1.5, 'iron'),
            ('Dry Cleaning', 'Professional dry cleaning', 5.0, 'dry_clean'),
            ('Darning', 'Repair and darning service', 3.0, 'darn');
        ");
    }

    // Seed admin user
    $adminCount = $db->query("SELECT COUNT(*) FROM users WHERE role='admin'")->fetchColumn();
    if ($adminCount == 0) {
        $hash = password_hash('admin123', PASSWORD_DEFAULT);
        $db->exec("INSERT INTO users (name, email, phone, password, role) VALUES ('Admin', 'admin@laundry.com', '0000000000', '$hash', 'admin')");
    }
}

initDB();
