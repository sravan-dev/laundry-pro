<?php
$pageTitle = 'Dashboard';
require_once 'includes/header.php';
require_once '../api/config/database.php';

$db = getDB();
$totalCustomers   = $db->query("SELECT COUNT(*) FROM users WHERE role='customer'")->fetchColumn();
$totalDelivery    = $db->query("SELECT COUNT(*) FROM users WHERE role='delivery_boy'")->fetchColumn();
$totalOrders      = $db->query("SELECT COUNT(*) FROM orders")->fetchColumn();
$pendingOrders    = $db->query("SELECT COUNT(*) FROM orders WHERE status='pending'")->fetchColumn();
$totalRevenue     = $db->query("SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status='delivered'")->fetchColumn();
$todayOrders      = $db->query("SELECT COUNT(*) FROM orders WHERE DATE(created_at)=DATE('now')")->fetchColumn();

$recentOrders = $db->query("
    SELECT o.*, c.name as customer_name, s.name as service_name
    FROM orders o
    LEFT JOIN users c ON o.customer_id = c.id
    LEFT JOIN services s ON o.service_id = s.id
    ORDER BY o.created_at DESC LIMIT 8
")->fetchAll();

$statusColors = [
    'pending'          => 'bg-yellow-100 text-yellow-700',
    'assigned'         => 'bg-blue-100 text-blue-700',
    'picked_up'        => 'bg-purple-100 text-purple-700',
    'washing'          => 'bg-indigo-100 text-indigo-700',
    'ready'            => 'bg-teal-100 text-teal-700',
    'out_for_delivery' => 'bg-orange-100 text-orange-700',
    'delivered'        => 'bg-green-100 text-green-700',
];

require_once 'includes/sidebar.php';
?>

<!-- Stats Cards -->
<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5 mb-6">
    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Total Customers</p>
                <p class="text-3xl font-bold text-gray-800 mt-1"><?= $totalCustomers ?></p>
            </div>
            <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-users text-blue-500 text-xl"></i>
            </div>
        </div>
        <a href="customers.php" class="text-xs text-blue-500 mt-3 inline-block hover:underline">View all →</a>
    </div>

    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Delivery Boys</p>
                <p class="text-3xl font-bold text-gray-800 mt-1"><?= $totalDelivery ?></p>
            </div>
            <div class="w-12 h-12 bg-orange-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-motorcycle text-orange-500 text-xl"></i>
            </div>
        </div>
        <a href="delivery_boys.php" class="text-xs text-orange-500 mt-3 inline-block hover:underline">View all →</a>
    </div>

    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Total Orders</p>
                <p class="text-3xl font-bold text-gray-800 mt-1"><?= $totalOrders ?></p>
            </div>
            <div class="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-box-open text-green-500 text-xl"></i>
            </div>
        </div>
        <a href="orders.php" class="text-xs text-green-500 mt-3 inline-block hover:underline">View all →</a>
    </div>

    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Pending Orders</p>
                <p class="text-3xl font-bold text-gray-800 mt-1"><?= $pendingOrders ?></p>
            </div>
            <div class="w-12 h-12 bg-yellow-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-clock text-yellow-500 text-xl"></i>
            </div>
        </div>
        <a href="orders.php?status=pending" class="text-xs text-yellow-500 mt-3 inline-block hover:underline">Review →</a>
    </div>

    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Total Revenue</p>
                <p class="text-3xl font-bold text-gray-800 mt-1">$<?= number_format($totalRevenue, 2) ?></p>
            </div>
            <div class="w-12 h-12 bg-emerald-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-dollar-sign text-emerald-500 text-xl"></i>
            </div>
        </div>
        <p class="text-xs text-gray-400 mt-3">From delivered orders</p>
    </div>

    <div class="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
        <div class="flex items-center justify-between">
            <div>
                <p class="text-sm text-gray-500 font-medium">Today's Orders</p>
                <p class="text-3xl font-bold text-gray-800 mt-1"><?= $todayOrders ?></p>
            </div>
            <div class="w-12 h-12 bg-purple-50 rounded-xl flex items-center justify-center">
                <i class="fas fa-calendar-day text-purple-500 text-xl"></i>
            </div>
        </div>
        <p class="text-xs text-gray-400 mt-3"><?= date('F j, Y') ?></p>
    </div>
</div>

<!-- Recent Orders -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100">
    <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <h3 class="font-semibold text-gray-800">Recent Orders</h3>
        <a href="orders.php" class="text-sm text-green-500 hover:underline">View all</a>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase">
                    <th class="px-6 py-3 text-left">Order #</th>
                    <th class="px-6 py-3 text-left">Customer</th>
                    <th class="px-6 py-3 text-left">Service</th>
                    <th class="px-6 py-3 text-left">Amount</th>
                    <th class="px-6 py-3 text-left">Status</th>
                    <th class="px-6 py-3 text-left">Date</th>
                    <th class="px-6 py-3 text-left">Action</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                <?php foreach ($recentOrders as $order): ?>
                <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4 font-semibold text-gray-700">#<?= $order['id'] ?></td>
                    <td class="px-6 py-4 text-gray-600"><?= htmlspecialchars($order['customer_name'] ?? 'N/A') ?></td>
                    <td class="px-6 py-4 text-gray-600"><?= htmlspecialchars($order['service_name'] ?? 'N/A') ?></td>
                    <td class="px-6 py-4 font-semibold text-gray-700">$<?= number_format($order['total_amount'], 2) ?></td>
                    <td class="px-6 py-4">
                        <span class="<?= $statusColors[$order['status']] ?? 'bg-gray-100 text-gray-600' ?> px-3 py-1 rounded-full text-xs font-semibold capitalize">
                            <?= str_replace('_', ' ', $order['status']) ?>
                        </span>
                    </td>
                    <td class="px-6 py-4 text-gray-400"><?= date('M j', strtotime($order['created_at'])) ?></td>
                    <td class="px-6 py-4">
                        <a href="orders.php?edit=<?= $order['id'] ?>" class="text-green-500 hover:text-green-600">
                            <i class="fas fa-eye"></i>
                        </a>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($recentOrders)): ?>
                <tr><td colspan="7" class="px-6 py-10 text-center text-gray-400">No orders yet</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
