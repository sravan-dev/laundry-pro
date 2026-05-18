<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?? 'Admin Panel' ?> — Laundry App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        primary: { DEFAULT: '#22c55e', dark: '#16a34a', light: '#bbf7d0' }
                    }
                }
            }
        }
    </script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"/>
    <style>
        .sidebar-link.active { background: #22c55e; color: white; }
        .sidebar-link.active i { color: white; }
        .sidebar-link:not(.active):hover { background: #f0fdf4; }
        .status-badge { @apply px-2 py-1 rounded-full text-xs font-semibold; }
    </style>
</head>
<body class="bg-gray-50 min-h-screen flex">
<?php
session_start();
if (!isset($_SESSION['admin'])) {
    header('Location: login.php');
    exit;
}
?>
