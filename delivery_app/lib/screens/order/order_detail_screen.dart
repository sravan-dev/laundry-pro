import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('delivery/orders.php?id=${widget.orderId}');
      if (mounted) {
        setState(() {
          _order = res['data'];
          _items = _order?['items'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      final res = await ApiService.put('delivery/orders.php', {
        'order_id': widget.orderId,
        'status': newStatus,
      });
      if (res['success'] == true) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to ${OrderStatus.label(newStatus)}'), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final status = _order!['status'] as String;
    final color = OrderStatus.color(status);
    final nextStatus = OrderStatus.nextStatus(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order #${widget.orderId}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.local_shipping, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(OrderStatus.label(status), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
                        Text('Order #${widget.orderId}', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('\$${(_order!['total_amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textDark)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer info
            _card('Customer Info', [
              _infoRow(Icons.person, 'Name', _order!['customer_name'] ?? 'N/A'),
              _infoRow(Icons.phone, 'Phone', _order!['customer_phone'] ?? 'N/A'),
              _infoRow(Icons.dry_cleaning, 'Service', _order!['service_name'] ?? 'N/A'),
              _infoRow(Icons.payment, 'Payment', (_order!['payment_method'] ?? 'cash').toString().toUpperCase()),
            ]),

            const SizedBox(height: 14),

            // Addresses
            _card('Addresses', [
              _addressCard('Pickup', _order!['pickup_address'] ?? '', Colors.green),
              const SizedBox(height: 10),
              _addressCard('Delivery', _order!['delivery_address'] ?? '', Colors.red),
            ]),

            // Items
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 14),
              _card('Items', [
                ..._items.where((i) => (i['quantity'] ?? 0) > 0).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.checkroom, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${item['item_name']} (${item['gender']})', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13)),
                          Text('x${item['quantity']}', style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                        ]),
                      ),
                      Text('\$${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ],
                  ),
                )),
              ]),
            ],

            // Preferences
            const SizedBox(height: 14),
            _card('Preferences', [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _prefChip(Icons.palette, '${_order!['color_preference'] ?? 'Color'} clothes'),
                _prefChip(Icons.thermostat, _order!['washing_temp'] ?? 'Celsius'),
                if (_order!['use_dry_heater'] == 1) _prefChip(Icons.local_fire_department, 'Dry Heater'),
                if (_order!['use_scented_detergent'] == 1) _prefChip(Icons.spa, 'Scented Detergent'),
                if (_order!['use_softener'] == 1) _prefChip(Icons.star, 'Softener'),
              ]),
              if (_order!['additional_note'] != null && _order!['additional_note'].toString().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.note, size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_order!['additional_note'], style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontStyle: FontStyle.italic))),
                  ]),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Action button
            if (nextStatus != null) ...[
              _buildUpdateButton(nextStatus),
            ] else if (status == 'delivered') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Order delivered successfully!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(String nextStatus) {
    final statusLabels = {
      'picked_up': ('Mark as Picked Up', Icons.motorcycle),
      'washing': ('Mark as Washing', Icons.local_laundry_service),
      'ready': ('Mark as Ready', Icons.check_circle_outline),
      'out_for_delivery': ('Out for Delivery', Icons.delivery_dining),
      'delivered': ('Mark as Delivered', Icons.done_all),
    };
    final info = statusLabels[nextStatus] ?? ('Update Status', Icons.update);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _updating ? null : () => _updateStatus(nextStatus),
        icon: _updating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(info.$2, size: 20),
        label: Text(info.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMedium),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ],
      ),
    );
  }

  Widget _addressCard(String type, String address, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
          ])),
        ],
      ),
    );
  }

  Widget _prefChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryLight)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
