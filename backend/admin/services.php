<?php
$pageTitle = 'Services';
require_once 'includes/header.php';
require_once '../api/config/database.php';

$db = getDB();
$message = '';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'add' || $action === 'edit') {
        $id          = (int)($_POST['id'] ?? 0);
        $name        = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $price       = (float)($_POST['price_per_item'] ?? 2.0);
        $icon        = trim($_POST['icon'] ?? '');
        $isActive    = (int)($_POST['is_active'] ?? 1);

        if (empty($name)) {
            $error = 'Service name is required.';
        } else {
            if ($action === 'add') {
                $stmt = $db->prepare("INSERT INTO services (name,description,price_per_item,icon,is_active) VALUES (?,?,?,?,?)");
                $stmt->execute([$name,$description,$price,$icon,$isActive]);
                $message = 'Service added successfully.';
            } else {
                $stmt = $db->prepare("UPDATE services SET name=?,description=?,price_per_item=?,icon=?,is_active=? WHERE id=?");
                $stmt->execute([$name,$description,$price,$icon,$isActive,$id]);
                $message = 'Service updated successfully.';
            }
        }
    }

    if ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        $db->prepare("DELETE FROM services WHERE id=?")->execute([$id]);
        $message = 'Service deleted.';
    }
}

$services = $db->query("SELECT * FROM services ORDER BY id")->fetchAll();

$editService = null;
$editId = (int)($_GET['edit'] ?? 0);
if ($editId) {
    $stmt = $db->prepare("SELECT * FROM services WHERE id=?");
    $stmt->execute([$editId]);
    $editService = $stmt->fetch();
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

<!-- Form -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 mb-6">
    <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <h3 class="font-semibold text-gray-800"><?= $editService ? 'Edit Service' : 'Add New Service' ?></h3>
        <?php if ($editService): ?>
        <a href="services.php" class="text-sm text-gray-400 hover:text-gray-600"><i class="fas fa-times mr-1"></i>Cancel</a>
        <?php endif; ?>
    </div>
    <form method="POST" class="p-6">
        <input type="hidden" name="action" value="<?= $editService ? 'edit' : 'add' ?>">
        <?php if ($editService): ?><input type="hidden" name="id" value="<?= $editService['id'] ?>"><?php endif; ?>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Service Name *</label>
                <input type="text" name="name" required value="<?= htmlspecialchars($editService['name'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="e.g. Wash & Iron">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Price per Item ($)</label>
                <input type="number" name="price_per_item" step="0.01" min="0"
                    value="<?= htmlspecialchars($editService['price_per_item'] ?? '2.00') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Icon Key</label>
                <input type="text" name="icon" value="<?= htmlspecialchars($editService['icon'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="wash_iron / iron / dry_clean / darn">
            </div>
            <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <input type="text" name="description" value="<?= htmlspecialchars($editService['description'] ?? '') ?>"
                    class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm"
                    placeholder="Service description...">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select name="is_active" class="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-green-400 outline-none text-sm">
                    <option value="1" <?= ($editService['is_active'] ?? 1) == 1 ? 'selected' : '' ?>>Active</option>
                    <option value="0" <?= ($editService['is_active'] ?? 1) == 0 ? 'selected' : '' ?>>Inactive</option>
                </select>
            </div>
        </div>
        <div class="mt-4">
            <button type="submit" class="bg-green-500 hover:bg-green-600 text-white px-6 py-2.5 rounded-xl font-semibold text-sm transition-colors">
                <i class="fas <?= $editService ? 'fa-save' : 'fa-plus' ?> mr-2"></i>
                <?= $editService ? 'Update Service' : 'Add Service' ?>
            </button>
        </div>
    </form>
</div>

<!-- Services Cards + Table -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100">
    <div class="px-6 py-4 border-b border-gray-100">
        <h3 class="font-semibold text-gray-800">All Services <span class="text-gray-400 font-normal text-sm">(<?= count($services) ?>)</span></h3>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 text-gray-500 text-xs uppercase">
                    <th class="px-6 py-3 text-left">#</th>
                    <th class="px-6 py-3 text-left">Service</th>
                    <th class="px-6 py-3 text-left">Description</th>
                    <th class="px-6 py-3 text-left">Price/Item</th>
                    <th class="px-6 py-3 text-left">Icon Key</th>
                    <th class="px-6 py-3 text-left">Status</th>
                    <th class="px-6 py-3 text-left">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                <?php foreach ($services as $svc): ?>
                <tr class="hover:bg-gray-50 transition-colors <?= $editId == $svc['id'] ? 'bg-green-50' : '' ?>">
                    <td class="px-6 py-4 text-gray-400"><?= $svc['id'] ?></td>
                    <td class="px-6 py-4 font-semibold text-gray-800"><?= htmlspecialchars($svc['name']) ?></td>
                    <td class="px-6 py-4 text-gray-500"><?= htmlspecialchars($svc['description'] ?? '—') ?></td>
                    <td class="px-6 py-4 font-semibold text-green-600">$<?= number_format($svc['price_per_item'], 2) ?></td>
                    <td class="px-6 py-4">
                        <code class="bg-gray-100 px-2 py-0.5 rounded text-xs text-gray-600"><?= htmlspecialchars($svc['icon'] ?? '') ?></code>
                    </td>
                    <td class="px-6 py-4">
                        <span class="<?= $svc['is_active'] ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500' ?> px-2 py-1 rounded-full text-xs font-semibold">
                            <?= $svc['is_active'] ? 'Active' : 'Inactive' ?>
                        </span>
                    </td>
                    <td class="px-6 py-4">
                        <div class="flex items-center gap-2">
                            <a href="?edit=<?= $svc['id'] ?>" class="w-8 h-8 bg-blue-50 text-blue-500 rounded-lg flex items-center justify-center hover:bg-blue-100" title="Edit">
                                <i class="fas fa-edit text-xs"></i>
                            </a>
                            <form method="POST" onsubmit="return confirm('Delete this service?')">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<?= $svc['id'] ?>">
                                <button type="submit" class="w-8 h-8 bg-red-50 text-red-500 rounded-lg flex items-center justify-center hover:bg-red-100" title="Delete">
                                    <i class="fas fa-trash text-xs"></i>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                <?php endforeach; ?>
                <?php if (empty($services)): ?>
                <tr><td colspan="7" class="px-6 py-10 text-center text-gray-400">No services found</td></tr>
                <?php endif; ?>
            </tbody>
        </table>
    </div>
</div>

<?php require_once 'includes/footer.php'; ?>
