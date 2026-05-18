<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$user = getAuthUser();
if ($user['role'] !== 'delivery_boy') {
    jsonResponse(['error' => 'Forbidden'], 403);
}

$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// GET: list assigned orders
if ($method === 'GET') {
    $orderId = $_GET['id'] ?? null;
    if ($orderId) {
        $stmt = $db->prepare("
            SELECT o.*, s.name as service_name, c.name as customer_name, c.phone as customer_phone
            FROM orders o
            LEFT JOIN services s ON o.service_id = s.id
            LEFT JOIN users c ON o.customer_id = c.id
            WHERE o.id = ? AND o.delivery_boy_id = ?
        ");
        $stmt->execute([$orderId, $user['id']]);
        $order = $stmt->fetch();
        if (!$order) jsonResponse(['error' => 'Order not found'], 404);

        $items = $db->prepare("SELECT * FROM order_items WHERE order_id = ?");
        $items->execute([$orderId]);
        $order['items'] = $items->fetchAll();
        jsonResponse(['success' => true, 'data' => $order]);
    }

    $status = $_GET['status'] ?? null;
    $where = "o.delivery_boy_id = ?";
    $params = [$user['id']];
    if ($status) {
        $where .= " AND o.status = ?";
        $params[] = $status;
    }

    $stmt = $db->prepare("
        SELECT o.*, s.name as service_name, c.name as customer_name, c.phone as customer_phone
        FROM orders o
        LEFT JOIN services s ON o.service_id = s.id
        LEFT JOIN users c ON o.customer_id = c.id
        WHERE $where
        ORDER BY o.created_at DESC
    ");
    $stmt->execute($params);
    jsonResponse(['success' => true, 'data' => $stmt->fetchAll()]);
}

// PUT: update order status
if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    $orderId = (int)($data['order_id'] ?? 0);
    $status  = $data['status'] ?? '';

    $validStatuses = ['picked_up', 'washing', 'ready', 'out_for_delivery', 'delivered'];
    if (!in_array($status, $validStatuses)) {
        jsonResponse(['error' => 'Invalid status'], 400);
    }

    $stmt = $db->prepare("UPDATE orders SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND delivery_boy_id = ?");
    $stmt->execute([$status, $orderId, $user['id']]);

    // Mark payment if delivered
    if ($status === 'delivered') {
        $db->prepare("UPDATE payments SET status = 'paid' WHERE order_id = ?")->execute([$orderId]);
    }

    jsonResponse(['success' => true, 'message' => 'Status updated']);
}

jsonResponse(['error' => 'Method not allowed'], 405);
