<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$user = getAuthUser();
$db = getDB();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $stmt = $db->prepare("SELECT id, name, email, phone, address, role, profile_image, created_at FROM users WHERE id = ?");
    $stmt->execute([$user['id']]);
    $profile = $stmt->fetch();
    if (!$profile) jsonResponse(['error' => 'User not found'], 404);
    jsonResponse(['success' => true, 'data' => $profile]);
}

if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    $name    = trim($data['name'] ?? '');
    $phone   = trim($data['phone'] ?? '');
    $address = trim($data['address'] ?? '');

    $stmt = $db->prepare("UPDATE users SET name = ?, phone = ?, address = ? WHERE id = ?");
    $stmt->execute([$name, $phone, $address, $user['id']]);
    jsonResponse(['success' => true, 'message' => 'Profile updated']);
}

jsonResponse(['error' => 'Method not allowed'], 405);
