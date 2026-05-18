<?php
require_once '../config/cors.php';
require_once '../config/database.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(['error' => 'Method not allowed'], 405);
}

$data = json_decode(file_get_contents('php://input'), true);
$name    = trim($data['name'] ?? '');
$email   = trim($data['email'] ?? '');
$phone   = trim($data['phone'] ?? '');
$password = $data['password'] ?? '';
$address  = trim($data['address'] ?? '');
$role    = $data['role'] ?? 'customer';

if (empty($name) || empty($email) || empty($password)) {
    jsonResponse(['error' => 'Name, email and password required'], 400);
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonResponse(['error' => 'Invalid email format'], 400);
}

if (strlen($password) < 6) {
    jsonResponse(['error' => 'Password must be at least 6 characters'], 400);
}

if (!in_array($role, ['customer', 'delivery_boy'])) {
    jsonResponse(['error' => 'Invalid role'], 400);
}

$db = getDB();
$existing = $db->prepare("SELECT id FROM users WHERE email = ?");
$existing->execute([$email]);
if ($existing->fetch()) {
    jsonResponse(['error' => 'Email already registered'], 409);
}

$hash = password_hash($password, PASSWORD_DEFAULT);
$stmt = $db->prepare("INSERT INTO users (name, email, phone, password, role, address) VALUES (?, ?, ?, ?, ?, ?)");
$stmt->execute([$name, $email, $phone, $hash, $role, $address]);
$userId = $db->lastInsertId();

$user = ['id' => (int)$userId, 'name' => $name, 'email' => $email, 'phone' => $phone, 'role' => $role, 'address' => $address];
$token = generateToken($user);

jsonResponse(['success' => true, 'token' => $token, 'user' => $user], 201);
