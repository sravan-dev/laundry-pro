<?php
$pageTitle = 'Orders';
require_once 'includes/header.php';
require_once '../api/config/database.php';

$db = getDB();
$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'assign') {
        $orderId   = (int)($_POST['order_id'] ?? 0);
        $deliveryId = (int)($_POST['delivery_boy_id'] ?? 0);
        $stmt = $db->prepare("UPDATE orders SET delivery_boy_id=?, status='assigned', updated_at=CURRENT_TIMESTAMP WHERE id=?");
        $stmt->execute([$deliveryId ?: null, $orderId]);
        $message = 'Delivery boy assigned.';
    }

    if ($action === 'update_status') {
        $orderId = (int)($_POST['order_id'] ?? 0);
        $status  = $_POST['status'] ?? '';
        $stmt = $db->prepare("UPDATE orders SET status=?, updated_at=CURRENT_TIMESTAMP WHERE id=?");
        $stmt->execute([$status, $orderId]);
        $message = 'Order status updated.';
    }

    if ($action === 'delete') {
        $orderId = (int)($_POST['id'] ?? 0);
        $db->prepare("DELETE FROM orders WHERE id=?")->execute([$orderId]);
        $message = 'Order deleted.';
    }
}

// Filters
$statusFilter = $_GET['status'] ?? '';
$search = trim($_GET['search'] ?? '');
$where = "WHERE 1=1";
$params = [];

if ($statusFilter) {
    $where .= " AND o.status = ?";
    $params[] = $statusFilter;
}
if ($search) {
    $where .= " AND (c.name LIKE ? OR c.email LIKE ? OR o.id LIKE ?)";
    $s = "%$search%";
    $params = array_merge($params, [$s, $s, $s]);
}

$orders = $db->prepare("
    SELECT o.*, c.name as customer_name, c.phone as customer_phone,
           d.name as delivery_boy_name, s.name as service_name
    FROM orders o
    LEFT JOIN users c ON o.customer_id = c.id
    LEFT JOIN users d ON o.delivery_boy_id = d.id
    LEFT JOIN services s ON o.service_id = s.id
    $where
    ORDER BY o.created_at DESC
");
$orders->execute($params);
$orders = $orders->fetchAll();

// Delivery boys for assignment
$deliveryBoys = $db->query("SELECT id, name FROM users WHERE role='delivery_boy' AND is_active=1 ORDER BY name")->fetchAll();

// Order detail modal
$viewId = (int)($_GET['view'] ?? 0);
$viewOrder = null;
$viewItems = [];
if ($viewId) {
    $stmt = $db->prepare("
        SELECT o.*, c.name as customer_name, c.phone as customer_phone,
               d.name as delivery_boy_name, s.name as service_name
        FROM orders o
        LEFT JOIN users c ON o.customer_id = c.id
        LEFT JOIN users d ON o.delivery_boy_id = d.id
        LEFT JOIN services s ON o.service_id = s.id
        WHERE o.id = ?
    ");
    $stmt->execute([$viewId]);
    $viewOrder = $stmt->fetch();
    if ($viewOrder) {
        $items = $db->prepare("SELECT * FROM order_items WHERE order_id=?");
        $items->execute([$viewId]);
        $viewItems = $items->fetchAll();
    }
}

$statusColors = [
    'pending'          => 'bg-yellow-100 text-yellow-700',
    'assigned'         => 'bg-blue-100 text-blue-700',
    'picked_up'        => 'bg-purple-100 text-purple-700',
    'washing'          => 'bg-indigo-100 text-indigo-700',
    'ready'            => 'bg-teal-100 text-teal-700',
    'out_for_delivery' => 'bg-orange-100 text-orange-700',
    'delivered'        => 'bg-green-100 text-green-700',
];

$allStatuses = ['pending','assigned','picked_up','washing','ready','out_for_delivery','delivered'];

require_once 'includes/sidebar.php';
?>

<?php if ($message): ?>
<div class="alert-auto mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-xl flex items-center gap-2">
    <i class="fas fa-check-circle"></i> <?= htmlspecialchars($message) ?>
</div>
<?php endif; ?>

<!-- Filter bar -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 mb-6 p-4">
    <form method="GET" class="flex flex-wrap gap-3 items-center">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>"
            placeholder="Search customer, order #..."
            class="px-4 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-green-400 outline-none flex-1 min-w-48">
        <select name="status" class="px-4 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-green-400 outline-none">
            <option value="">All Statuses</option>
            <?php foreach ($allStatuses as $s): ?>
            <option value="<?= $s ?>" <?= $statusFilter === $s ? 'selected' : '' ?>><?= ucwords(str_replace('_',' ',$s)) ?></option>
            <?php endforeach; ?>
        </select>
        <button type="submit" class="bg-green-500 text-white px-5 py-2 rounded-xl text-sm hover:bg-green-600 font-medium">
            <i class="fas fa-filter mr-1"></i>Filter
        </button>
        <a href="orders.php" class="px-5 py-2 border border-gray-200 rounded-xl text-sm text-gray-500 hover:bg-gray-50">Reset</a>
    </form>
</div>

<!-- Orders Table -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100">
    <div class="px-6 py-4 border-b border-gray-100">
        <h3 class="font-semibold text-gray-800">All Orders <span class="text-gray-400 font-normal text-sm">(<?= count($orders) ?>)</span></h3>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase">
                    <th class="px-4 py-3 text-left">Order</th>
                    <th class="px-4 py-3 text-left">Customer</th>
                    <th class="px-4 py-3 text-left">Service</th>
                    <th class="px-4 py-3 text-left">Amount</th>
                    <th class="px-4 py-3 text-left">Status</th>
                    <th class="px-4 py-3 text-left">Delivery Boy</th>
                    <th class="px-4 py-3 text-left">Date</th>
                    <th class="px-4 py-3 text-left">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                <?php foreach ($orders as $o): ?>
                <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-4 py-4 font-bold text-green-600">#<?= $o['id'] ?></td>
                    <td class="px-4 py-4">
                        <p class="font-medium text-gray-800"><?= htmlspecialchars($o['customer_name'] ?? 'N/A') ?></p>
                        <p class="text-xs text-gray-400"><?= htmlspecialchars($o['customer_phone'] ?? '') ?></p>
                    </td>
                    <td class="px-4 py-4 text-gray-600"><?= htmlspecialchars($o['service_name'] ?? 'N/A') ?></td>
                    <td class="px-4 py-4 font-semibold text-gray-800">$<?= number_format($o['total_amount'], 2) ?></td>
                    <td class="px-4 py-4">
                        <form method="POST" class="inline">
                            <input type="hidden" name="action" value="update_status">
                            <input type="hidden" name="order_id" value="<?= $o['id'] ?>">
                            <select name="status" onchange="this.form.submit()"
                                class="<?= $statusColors[$o['status']] ?? 'bg-gray-100 text-gray-600' ?> border-0 rounded-full text-xs font-semibold px-2 py-1 cursor-pointer focus:outline-none">
                                <?php foreach ($allStatuses as $s): ?>
                                <option value="<?= $s ?>" <?= $o['status'] === $s ? 'selected' : '' ?>><?= ucwords(str_replace('_',' ',$s)) ?></option>
                                <?php endforeach; ?>
                            </select>
                        </form>
                    </td>
                    <td class="px-4 py-4">
                        <form method="POST" class="flex items-center gap-1">
                            <input type="hidden" name="action" value="assign">
                            <input type="hidden" name="order_id" value="<?= $o['id'] ?>">
                            <select name="delivery_boy_id" class="border border-gray-200 rounded-lg text-xs px-2 py-1 focus:ring-1 focus:ring-green-400 outline-none">
                                <option value="">— Assign —</option>
                                <?php foreach ($deliveryBoys as $db_boy): ?>
                                <option value="<?= $db_boy['id'] ?>" <?= $o['delivery_boy_id'] == $db_boy['id'] ? 'selected' : '' ?>><?= htmlspecialchars($db_boy['name']) ?></option>
                                <?php endforeach; ?>
                            </select>
                            <button type="submit" class="bg-green-500 text-white text-xs px-2 py-1 rounded-lg hover:bg-green-600">
                                <i class="fas fa-check"></i>
                            </button>
                        </form>
                    </td>
                    <td class="px-4 py-4 text-gray-400 text-xs"><?= date('M j, Y H:i', strtotime($o['created_at'])) ?></td>
                    <td class="px-4 py-4">
                        <div class="flex items-center gap-1">
                            <a href="?view=<?= $o['id'] ?><?= $statusFilter ? '&status='.$statusFilter : '' ?>"
                               class="w-8 h-8 bg-green-50 text-green-500 rounded-lg flex items-center justify-center hover:bg-green-100" title="View">
                                <i class="fas fa-eye text-xs"></i>
                            </a>
                            <form method="POST" onsubmit="return confirm('Delete order #<?= $o['id'] ?>?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= $o['id'] ?>">
                                <button type="submit" class="w-8 h-8 bg-red-50 text-red-500 rounded-lg flex items-center justify-center hover:bg-red-100" title="Delete">
                                    <i class="fas fa-trash text-xs"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($orders)): ?>
                <tr><td colspan="8" class="px-6 py-10 text-center text-gray-400">No orders found</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<!-- Order Detail Modal -->
<?php if ($viewOrder): ?>
<div class="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4" id="orderModal">
    <div class="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100 sticky top-0 bg-white">
            <h3 class="font-bold text-gray-800 text-lg">Order #<?= $viewOrder['id'] ?> Details</h3>
            <a href="orders.php<?= $statusFilter ? '?status='.$statusFilter : '' ?>" class="text-gray-400 hover:text-gray-600">
                <i class="fas fa-times text-lg"></i>
            </a>
        </div>
        <div class="p-6 space-y-5">
            <!-- Status -->
            <div class="flex items-center gap-3">
                <span class="<?= $statusColors[$viewOrder['status']] ?? 'bg-gray-100 text-gray-600' ?> px-4 py-1.5 rounded-full text-sm font-semibold capitalize">
                    <?= str_replace('_', ' ', $viewOrder['status']) ?>
                </span>
                <span class="text-gray-400 text-sm"><?= date('F j, Y \a\t H:i', strtotime($viewOrder['created_at'])) ?></span>
            </div>

            <div class="grid grid-cols-2 gap-4">
                <div class="bg-gray-50 rounded-xl p-4">
                    <p class="text-xs text-gray-400 mb-1 font-medium uppercase tracking-wide">Customer</p>
                    <p class="font-semibold text-gray-800"><?= htmlspecialchars($viewOrder['customer_name']) ?></p>
                    <p class="text-sm text-gray-500"><?= htmlspecialchars($viewOrder['customer_phone'] ?? '') ?></p>
                </div>
                <div class="bg-gray-50 rounded-xl p-4">
                    <p class="text-xs text-gray-400 mb-1 font-medium uppercase tracking-wide">Delivery Boy</p>
                    <p class="font-semibold text-gray-800"><?= htmlspecialchars($viewOrder['delivery_boy_name'] ?? 'Not assigned') ?></p>
                    <p class="text-sm text-gray-500"><?= htmlspecialchars($viewOrder['service_name'] ?? '') ?></p>
                </div>
                <div class="bg-gray-50 rounded-xl p-4">
                    <p class="text-xs text-gray-400 mb-1 font-medium uppercase tracking-wide">Pickup Address</p>
                    <p class="text-sm text-gray-700"><?= htmlspecialchars($viewOrder['pickup_address']) ?></p>
                </div>
                <div class="bg-gray-50 rounded-xl p-4">
                    <p class="text-xs text-gray-400 mb-1 font-medium uppercase tracking-wide">Delivery Address</p>
                    <p class="text-sm text-gray-700"><?= htmlspecialchars($viewOrder['delivery_address']) ?></p>
                </div>
            </div>

            <!-- Preferences -->
            <div class="bg-gray-50 rounded-xl p-4">
                <p class="text-xs text-gray-400 mb-2 font-medium uppercase tracking-wide">Preferences</p>
                <div class="flex flex-wrap gap-2">
                    <span class="bg-white border border-gray-200 px-3 py-1 rounded-full text-xs text-gray-600">
                        <i class="fas fa-palette mr-1 text-purple-400"></i><?= ucfirst($viewOrder['color_preference']) ?> Clothes
                    </span>
                    <span class="bg-white border border-gray-200 px-3 py-1 rounded-full text-xs text-gray-600">
                        <i class="fas fa-thermometer mr-1 text-red-400"></i><?= ucfirst($viewOrder['washing_temp']) ?>
                    </span>
                    <?php if ($viewOrder['use_dry_heater']): ?>
                    <span class="bg-white border border-gray-200 px-3 py-1 rounded-full text-xs text-gray-600"><i class="fas fa-fire mr-1 text-orange-400"></i>Dry Heater</span>
                    <?php endif; ?>
                    <?php if ($viewOrder['use_scented_detergent']): ?>
                    <span class="bg-white border border-gray-200 px-3 py-1 rounded-full text-xs text-gray-600"><i class="fas fa-spray-can mr-1 text-blue-400"></i>Scented Detergent</span>
                    <?php endif; ?>
                    <?php if ($viewOrder['use_softener']): ?>
                    <span class="bg-white border border-gray-200 px-3 py-1 rounded-full text-xs text-gray-600"><i class="fas fa-star mr-1 text-yellow-400"></i>Softener</span>
                    <?php endif; ?>
                </div>
                <?php if ($viewOrder['additional_note']): ?>
                <p class="mt-2 text-sm text-gray-600 italic">"<?= htmlspecialchars($viewOrder['additional_note']) ?>"</p>
                <?php endif; ?>
            </div>

            <!-- Items -->
            <?php if (!empty($viewItems)): ?>
            <div>
                <p class="text-xs text-gray-400 mb-2 font-medium uppercase tracking-wide">Items</p>
                <div class="border border-gray-100 rounded-xl overflow-hidden">
                    <table class="w-full text-sm">
                        <thead><tr class="bg-gray-50 text-gray-500 text-xs">
                            <th class="px-4 py-2 text-left">Item</th>
                            <th class="px-4 py-2 text-left">Gender</th>
                            <th class="px-4 py-2 text-center">Qty</th>
                            <th class="px-4 py-2 text-right">Price</th>
                        </tr></thead>
                        <tbody class="divide-y divide-gray-50">
                            <?php foreach ($viewItems as $item): ?>
                            <?php if ($item['quantity'] > 0): ?>
                            <tr>
                                <td class="px-4 py-2 font-medium text-gray-700"><?= htmlspecialchars($item['item_name']) ?></td>
                                <td class="px-4 py-2 text-gray-500 capitalize"><?= htmlspecialchars($item['gender']) ?></td>
                                <td class="px-4 py-2 text-center text-gray-600"><?= $item['quantity'] ?></td>
                                <td class="px-4 py-2 text-right font-semibold text-gray-800">$<?= number_format($item['price'] * $item['quantity'], 2) ?></td>
                            </tr>
                            <?php endif; ?>
                            <?php endforeach; ?>
                        </tbody>
                        <tfoot>
                            <tr class="bg-green-50">
                                <td colspan="3" class="px-4 py-2 font-bold text-gray-700 text-right">Total</td>
                                <td class="px-4 py-2 text-right font-bold text-green-600 text-base">$<?= number_format($viewOrder['total_amount'], 2) ?></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
            <?php endif; ?>
        </div>
    </div>
</div>
<?php endif; ?>

<?php require_once 'includes/footer.php'; ?>
