<?php
$currentPage = basename($_SERVER['PHP_SELF'], '.php');
function navLink($href, $icon, $label, $current) {
    $page = basename($href, '.php');
    $active = $page === $current ? 'active' : '';
    echo "<a href='$href' class='sidebar-link $active flex items-center gap-3 px-4 py-3 rounded-xl text-gray-600 font-medium transition-all'>
        <i class='$icon w-5 text-center text-gray-400'></i>
        <span>$label</span>
    </a>";
}
?>
<aside class="w-64 min-h-screen bg-white shadow-lg flex flex-col fixed top-0 left-0 z-30">
    <!-- Logo -->
    <div class="flex items-center gap-3 px-6 py-5 border-b border-gray-100">
        <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
            <i class="fas fa-tshirt text-white text-lg"></i>
        </div>
        <div>
            <h1 class="font-bold text-gray-800 text-lg leading-tight">LaundryPro</h1>
            <p class="text-xs text-gray-400">Admin Panel</p>
        </div>
    </div>

    <!-- Nav -->
    <nav class="flex-1 px-3 py-4 space-y-1">
        <?php navLink('index.php', 'fas fa-chart-line', 'Dashboard', $currentPage); ?>
        <?php navLink('customers.php', 'fas fa-users', 'Customers', $currentPage); ?>
        <?php navLink('delivery_boys.php', 'fas fa-motorcycle', 'Delivery Boys', $currentPage); ?>
        <?php navLink('orders.php', 'fas fa-box-open', 'Orders', $currentPage); ?>
        <?php navLink('services.php', 'fas fa-concierge-bell', 'Services', $currentPage); ?>
    </nav>

    <!-- User info -->
    <div class="px-4 py-4 border-t border-gray-100">
        <div class="flex items-center gap-3 mb-3">
            <div class="w-9 h-9 bg-primary-light rounded-full flex items-center justify-center">
                <i class="fas fa-user-shield text-primary text-sm"></i>
            </div>
            <div>
                <p class="text-sm font-semibold text-gray-700"><?= htmlspecialchars($_SESSION['admin']['name'] ?? 'Admin') ?></p>
                <p class="text-xs text-gray-400">Administrator</p>
            </div>
        </div>
        <a href="logout.php" class="flex items-center gap-2 text-sm text-red-500 hover:text-red-600 font-medium px-2">
            <i class="fas fa-sign-out-alt"></i> Logout
        </a>
    </div>
</aside>

<!-- Main content wrapper -->
<div class="ml-64 flex-1 flex flex-col min-h-screen">
    <!-- Top bar -->
    <header class="bg-white shadow-sm px-6 py-4 flex items-center justify-between sticky top-0 z-20">
        <h2 class="text-xl font-bold text-gray-800"><?= $pageTitle ?? 'Dashboard' ?></h2>
        <div class="flex items-center gap-3 text-sm text-gray-500">
            <i class="fas fa-calendar"></i>
            <?= date('F j, Y') ?>
        </div>
    </header>

    <!-- Page content -->
    <main class="flex-1 p-6">
