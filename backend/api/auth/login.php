<?php
require_once '../config/cors.php';
require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['error' => 'Method not allowed'], 405);
}

$data = json_decode(file_get_contents('php://input'), true);
$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';
$role = $data['role'] ?? 'customer'; // customer | delivery_boy

if (empty($email) || empty($password)) {
    jsonResponse(['error' => 'Email and password required'], 400);
}

$db = getDB();
$stmt = $db->prepare("SELECT * FROM users WHERE email = ? AND role = ? AND is_active = 1");
$stmt->execute([$email, $role]);
$user = $stmt->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    jsonResponse(['error' => 'Invalid credentials'], 401);
}

unset($user['password']);
$token = generateToken($user);

jsonResponse([
    'success' => true,
    'token' => $token,
    'user' => $user
]);
