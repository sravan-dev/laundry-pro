<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$user = getAuthUser();
if ($user['role'] !== 'customer') {
    jsonResponse(['error' => 'Forbidden'], 403);
}

$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// GET: list customer orders
if ($method === 'GET') {
    $orderId = $_GET['id'] ?? null;
    if ($orderId) {
        $stmt = $db->prepare("
            SELECT o.*, s.name as service_name, u.name as delivery_boy_name
            FROM orders o
            LEFT JOIN services s ON o.service_id = s.id
            LEFT JOIN users u ON o.delivery_boy_id = u.id
            WHERE o.id = ? AND o.customer_id = ?
        ");
        $stmt->execute([$orderId, $user['id']]);
        $order = $stmt->fetch();
        if (!$order) jsonResponse(['error' => 'Order not found'], 404);

        $items = $db->prepare("SELECT * FROM order_items WHERE order_id = ?");
        $items->execute([$orderId]);
        $order['items'] = $items->fetchAll();
        jsonResponse(['success' => true, 'data' => $order]);
    }

    $stmt = $db->prepare("
        SELECT o.*, s.name as service_name
        FROM orders o
        LEFT JOIN services s ON o.service_id = s.id
        WHERE o.customer_id = ?
        ORDER BY o.created_at DESC
    ");
    $stmt->execute([$user['id']]);
    jsonResponse(['success' => true, 'data' => $stmt->fetchAll()]);
}

// POST: place new order
if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $serviceId       = (int)($data['service_id'] ?? 0);
    $pickupAddress   = trim($data['pickup_address'] ?? '');
    $deliveryAddress = trim($data['delivery_address'] ?? '');
    $items           = $data['items'] ?? [];

    if (!$serviceId || empty($pickupAddress) || empty($deliveryAddress)) {
        jsonResponse(['error' => 'Missing required fields'], 400);
    }
    if (empty($items)) {
        jsonResponse(['error' => 'At least one item required'], 400);
    }

    $colorPref  = $data['color_preference'] ?? 'color';
    $washTemp   = $data['washing_temp'] ?? 'celsius';
    $dryHeater  = (int)($data['use_dry_heater'] ?? 0);
    $scented    = (int)($data['use_scented_detergent'] ?? 0);
    $softener   = (int)($data['use_softener'] ?? 0);
    $note       = trim($data['additional_note'] ?? '');
    $payMethod  = $data['payment_method'] ?? 'cash';

    // Calculate total
    $total = 0;
    foreach ($items as $item) {
        $total += ((float)($item['price'] ?? 2.0)) * ((int)($item['quantity'] ?? 0));
    }

    $stmt = $db->prepare("
        INSERT INTO orders (customer_id, service_id, pickup_address, delivery_address, total_amount,
            color_preference, washing_temp, use_dry_heater, use_scented_detergent, use_softener,
            additional_note, payment_method)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ");
    $stmt->execute([
        $user['id'], $serviceId, $pickupAddress, $deliveryAddress, $total,
        $colorPref, $washTemp, $dryHeater, $scented, $softener, $note, $payMethod
    ]);
    $orderId = $db->lastInsertId();

    // Insert items
    $itemStmt = $db->prepare("INSERT INTO order_items (order_id, item_name, gender, quantity, price) VALUES (?, ?, ?, ?, ?)");
    foreach ($items as $item) {
        $qty = (int)($item['quantity'] ?? 0);
        if ($qty > 0) {
            $itemStmt->execute([$orderId, $item['item_name'], $item['gender'] ?? 'unisex', $qty, $item['price'] ?? 2.0]);
        }
    }

    jsonResponse(['success' => true, 'order_id' => (int)$orderId, 'total' => (float)$total], 201);
}

jsonResponse(['error' => 'Method not allowed'], 405);
