<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$user = getAuthUser();
if ($user['role'] !== 'admin') {
    jsonResponse(['error' => 'Forbidden'], 403);
}

$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];
$role = $_GET['role'] ?? 'customer';

if ($method === 'GET') {
    $userId = $_GET['id'] ?? null;
    if ($userId) {
        $stmt = $db->prepare("SELECT id,name,email,phone,address,role,is_active,created_at FROM users WHERE id=?");
        $stmt->execute([$userId]);
        jsonResponse(['success' => true, 'data' => $stmt->fetch()]);
    }
    $stmt = $db->prepare("SELECT id,name,email,phone,address,role,is_active,created_at FROM users WHERE role=? ORDER BY created_at DESC");
    $stmt->execute([$role]);
    jsonResponse(['success' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $hash = password_hash($data['password'] ?? 'password123', PASSWORD_DEFAULT);
    $stmt = $db->prepare("INSERT INTO users (name,email,phone,password,role,address) VALUES (?,?,?,?,?,?)");
    $stmt->execute([$data['name'],$data['email'],$data['phone'],$hash,$data['role'],$data['address']??'']);
    jsonResponse(['success' => true, 'id' => $db->lastInsertId()], 201);
}

if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    $stmt = $db->prepare("UPDATE users SET name=?,email=?,phone=?,address=?,is_active=? WHERE id=?");
    $stmt->execute([$data['name'],$data['email'],$data['phone']??'',$data['address']??'',$data['is_active']??1,$data['id']]);
    jsonResponse(['success' => true]);
}

if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    $db->prepare("DELETE FROM users WHERE id=? AND role!='admin'")->execute([$id]);
    jsonResponse(['success' => true]);
}

jsonResponse(['error' => 'Method not allowed'], 405);
