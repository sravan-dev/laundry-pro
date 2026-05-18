<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$user = getAuthUser();
if ($user['role'] !== 'admin') {
    jsonResponse(['error' => 'Forbidden'], 403);
}

$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $orderId = $_GET['id'] ?? null;
    if ($orderId) {
        $stmt = $db->prepare("
            SELECT o.*, c.name as customer_name, d.name as delivery_boy_name, s.name as service_name
            FROM orders o
            LEFT JOIN users c ON o.customer_id=c.id
            LEFT JOIN users d ON o.delivery_boy_id=d.id
            LEFT JOIN services s ON o.service_id=s.id
            WHERE o.id=?
        ");
        $stmt->execute([$orderId]);
        $order = $stmt->fetch();
        if ($order) {
            $items = $db->prepare("SELECT * FROM order_items WHERE order_id=?");
            $items->execute([$orderId]);
            $order['items'] = $items->fetchAll();
        }
        jsonResponse(['success' => true, 'data' => $order]);
    }

    $status = $_GET['status'] ?? null;
    $where = $status ? "WHERE o.status='$status'" : "";
    $orders = $db->query("
        SELECT o.*, c.name as customer_name, d.name as delivery_boy_name, s.name as service_name
        FROM orders o
        LEFT JOIN users c ON o.customer_id=c.id
        LEFT JOIN users d ON o.delivery_boy_id=d.id
        LEFT JOIN services s ON o.service_id=s.id
        $where
        ORDER BY o.created_at DESC
    ")->fetchAll();
    jsonResponse(['success' => true, 'data' => $orders]);
}

if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = (int)$data['id'];
    $status = $data['status'] ?? null;
    $deliveryBoyId = $data['delivery_boy_id'] ?? null;

    $fields = [];
    $params = [];
    if ($status) { $fields[] = "status=?"; $params[] = $status; }
    if ($deliveryBoyId !== null) { $fields[] = "delivery_boy_id=?"; $params[] = $deliveryBoyId ?: null; }
    $fields[] = "updated_at=CURRENT_TIMESTAMP";
    $params[] = $id;

    $db->prepare("UPDATE orders SET " . implode(',', $fields) . " WHERE id=?")->execute($params);
    jsonResponse(['success' => true]);
}

if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    $db->prepare("DELETE FROM orders WHERE id=?")->execute([$id]);
    jsonResponse(['success' => true]);
}

jsonResponse(['error' => 'Method not allowed'], 405);
