<?php
$pageTitle = 'Customers';
require_once 'includes/header.php';
require_once '../api/config/database.php';

$db = getDB();
$message = '';
$error = '';

// Handle POST actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'add' || $action === 'edit') {
        $id      = (int)($_POST['id'] ?? 0);
        $name    = trim($_POST['name'] ?? '');
        $email   = trim($_POST['email'] ?? '');
        $phone   = trim($_POST['phone'] ?? '');
        $address = trim($_POST['address'] ?? '');
        $isActive = (int)($_POST['is_active'] ?? 1);

        if (empty($name) || empty($email)) {
            $error = 'Name and email are required.';
        } else {
            if ($action === 'add') {
                $password = $_POST['password'] ?? 'customer123';
                $hash = password_hash($password, PASSWORD_DEFAULT);
                try {
                    $stmt = $db->prepare("INSERT INTO users (name,email,phone,password,role,address,is_active) VALUES (?,?,?,?,'customer',?,?)");
                    $stmt->execute([$name,$email,$phone,$hash,$address,$isActive]);
                    $message = 'Customer added successfully.';
                } catch (Exception $e) {
                    $error = 'Email already exists.';
                }
            } else {
                $stmt = $db->prepare("UPDATE users SET name=?,email=?,phone=?,address=?,is_active=? WHERE id=? AND role='customer'");
                $stmt->execute([$name,$email,$phone,$address,$isActive,$id]);
                $message = 'Customer updated successfully.';
            }
        }
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        $db->prepare("DELETE FROM users WHERE id=? AND role='customer'")->execute([$id]);
        $message = 'Customer deleted successfully.';
    }
}

$search = trim($_GET['search'] ?? '');
$where = "WHERE role='customer'";
$params = [];
if ($search) {
    $where .= " AND (name LIKE ? OR email LIKE ? OR phone LIKE ?)";
    $s = "%$search%";
    $params = [$s, $s, $s];
}

$customers = $db->prepare("SELECT * FROM users $where ORDER BY created_at DESC");
$customers->execute($params);
$customers = $customers->fetchAll();

$editCustomer = null;
$editId = (int)($_GET['edit'] ?? 0);
if ($editId) {
    $stmt = $db->prepare("SELECT * FROM users WHERE id=? AND role='customer'");
    $stmt->execute([$editId]);
    $editCustomer = $stmt->fetch();
}

require_once 'includes/sidebar.php';
?>

<?php if ($message): ?>
<div class="alert-auto mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-xl flex items-center gap-2">
    <i class="fas fa-check-circle"></i> <?= htmlspecialchars($message) ?>
</div>
<?php endif; ?>
<?php if ($error): ?>
<div class="alert-auto mb-4 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-xl flex items-center gap-2">
    <i class="fas fa-exclamation-circle"></i> <?= htmlspecialchars($error) ?>
</div>
<?php endif; ?>

<!-- Add / Edit Form -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 mb-6">
    <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <h3 class="font-semibold text-gray-800">
            <?= $editCustomer ? 'Edit Customer' : 'Add New Customer' ?>
        </h3>
        <?php if ($editCustomer): ?>
        <a href="customers.php" class="text-sm text-gray-400 hover:text-gray-600">
            <i class="fas fa-times mr-1"></i>Cancel Edit
        </a>
        <?php endif; ?>
    </div>
    <form method="POST" class="p-6">
        <input type="hidden" name="action" value="<?= $editCustomer ? 'edit' : 'add' ?>">
        <?php if ($editCustomer): ?>
        <input type="hidden" name="id" value="<?= $editCustomer['id'] ?>">
        <?php endif; ?>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
                <input type="text" name="name" required
                    value="<?= htmlspecialchars($editCustomer['name'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="John Doe">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Email *</label>
                <input type="email" name="email" required
                    value="<?= htmlspecialchars($editCustomer['email'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="john@example.com">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input type="text" name="phone"
                    value="<?= htmlspecialchars($editCustomer['phone'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="+1 555 0000">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Address</label>
                <input type="text" name="address"
                    value="<?= htmlspecialchars($editCustomer['address'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="123 Main St">
            </div>
            <?php if (!$editCustomer): ?>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input type="text" name="password" value="customer123"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm">
            </div>
            <?php endif; ?>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="is_active" class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm">
                    <option value="1" <?= ($editCustomer['is_active'] ?? 1) == 1 ? 'selected' : '' ?>>Active</option>
                    <option value="0" <?= ($editCustomer['is_active'] ?? 1) == 0 ? 'selected' : '' ?>>Inactive</option>
                </select>
            </div>
        </div>
        <div class="mt-4">
            <button type="submit"
                class="bg-green-500 hover:bg-green-600 text-white px-6 py-2.5 rounded-xl font-semibold text-sm transition-colors">
                <i class="fas <?= $editCustomer ? 'fa-save' : 'fa-plus' ?> mr-2"></i>
                <?= $editCustomer ? 'Update Customer' : 'Add Customer' ?>
            </button>
        </div>
    </form>
</div>

<!-- Search + Table -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100">
    <div class="px-6 py-4 border-b border-gray-100 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
        <h3 class="font-semibold text-gray-800">All Customers <span class="text-gray-400 font-normal text-sm">(<?= count($customers) ?>)</span></h3>
        <form method="GET" class="flex gap-2">
            <input type="text" name="search" value="<?= htmlspecialchars($search) ?>"
                placeholder="Search name, email, phone..."
                class="px-4 py-2 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-green-400 outline-none w-64">
            <button type="submit" class="bg-green-500 text-white px-4 py-2 rounded-xl text-sm hover:bg-green-600">
                <i class="fas fa-search"></i>
            </button>
            <?php if ($search): ?>
            <a href="customers.php" class="px-4 py-2 border border-gray-200 rounded-xl text-sm text-gray-500 hover:bg-gray-50">Clear</a>
            <?php endif; ?>
        </form>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase">
                    <th class="px-6 py-3 text-left">#</th>
                    <th class="px-6 py-3 text-left">Name</th>
                    <th class="px-6 py-3 text-left">Email</th>
                    <th class="px-6 py-3 text-left">Phone</th>
                    <th class="px-6 py-3 text-left">Address</th>
                    <th class="px-6 py-3 text-left">Status</th>
                    <th class="px-6 py-3 text-left">Joined</th>
                    <th class="px-6 py-3 text-left">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                <?php foreach ($customers as $c): ?>
                <tr class="hover:bg-gray-50 transition-colors <?= $editId == $c['id'] ? 'bg-green-50' : '' ?>">
                    <td class="px-6 py-4 text-gray-400"><?= $c['id'] ?></td>
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-3">
                            <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center text-green-600 font-semibold text-xs">
                                <?= strtoupper(substr($c['name'], 0, 2)) ?>
                            </div>
                            <span class="font-medium text-gray-800"><?= htmlspecialchars($c['name']) ?></span>
                        </div>
                    </td>
                    <td class="px-6 py-4 text-gray-600"><?= htmlspecialchars($c['email']) ?></td>
                    <td class="px-6 py-4 text-gray-600"><?= htmlspecialchars($c['phone'] ?? '—') ?></td>
                    <td class="px-6 py-4 text-gray-600 max-w-xs truncate"><?= htmlspecialchars($c['address'] ?? '—') ?></td>
                    <td class="px-6 py-4">
                        <span class="<?= $c['is_active'] ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-600' ?> px-2 py-1 rounded-full text-xs font-semibold">
                            <?= $c['is_active'] ? 'Active' : 'Inactive' ?>
                        </span>
                    </td>
                    <td class="px-6 py-4 text-gray-400"><?= date('M j, Y', strtotime($c['created_at'])) ?></td>
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-2">
                            <a href="?edit=<?= $c['id'] ?>" class="w-8 h-8 bg-blue-50 text-blue-500 rounded-lg flex items-center justify-center hover:bg-blue-100 transition-colors" title="Edit">
                                <i class="fas fa-edit text-xs"></i>
                            </a>
                            <form method="POST" onsubmit="confirmDelete(event, this)">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= $c['id'] ?>">
                                <button type="submit" class="w-8 h-8 bg-red-50 text-red-500 rounded-lg flex items-center justify-center hover:bg-red-100 transition-colors" title="Delete">
                                    <i class="fas fa-trash text-xs"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($customers)): ?>
                <tr><td colspan="8" class="px-6 py-10 text-center text-gray-400">No customers found</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<script>
function confirmDelete(e, form) {
    if (!confirm('Delete this customer? This cannot be undone.')) {
        e.preventDefault();
    }
}
</script>

<?php require_once 'includes/footer.php'; ?>
