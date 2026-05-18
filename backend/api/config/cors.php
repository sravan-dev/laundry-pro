<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

function jsonResponse($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data);
    exit;
}

function getAuthUser() {
    $headers = getallheaders();

    // Case-insensitive header search + $_SERVER fallback
    $token = '';
    foreach ($headers as $key => $value) {
        if (strtolower($key) === 'authorization') {
            $token = $value;
            break;
        }
    }
    if (empty($token)) {
        $token = $_SERVER['HTTP_AUTHORIZATION']
              ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
              ?? '';
    }

    // Log for debugging
    $log = date('H:i:s') . ' ' . $_SERVER['REQUEST_METHOD'] . ' '
         . ($_SERVER['REQUEST_URI'] ?? '') . ' | headers: '
         . json_encode($headers) . ' | token_found: ' . ($token ? 'yes' : 'NO') . "\n";
    file_put_contents('/tmp/laundry_auth.log', $log, FILE_APPEND);

    if (str_starts_with($token, 'Bearer ')) {
        $token = substr($token, 7);
    }
    if (empty($token)) {
        jsonResponse(['error' => 'Unauthorized'], 401);
    }
    $decoded = base64_decode($token);
    $parts = explode(':', $decoded, 3);
    if (count($parts) < 2) {
        jsonResponse(['error' => 'Invalid token'], 401);
    }
    return ['id' => (int)$parts[0], 'role' => $parts[1], 'email' => $parts[2] ?? ''];
}

function generateToken($user) {
    return base64_encode($user['id'] . ':' . $user['role'] . ':' . $user['email']);
}
