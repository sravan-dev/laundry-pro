<?php
require_once '../config/cors.php';
require_once '../config/database.php';

$db = getDB();
$services = $db->query("SELECT * FROM services WHERE is_active = 1 ORDER BY id")->fetchAll();
jsonResponse(['success' => true, 'data' => $services]);
