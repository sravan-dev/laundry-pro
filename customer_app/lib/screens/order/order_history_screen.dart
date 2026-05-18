import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('customer/orders.php');
      if (mounted) {
        setState(() {
          _orders = (res['data'] as List).map((o) => OrderModel.fromJson(o)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _orders.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Place your first order from the home screen', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final color = OrderStatus.color(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id}', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(OrderStatus.label(order.status), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dry_cleaning, color: AppColors.textMedium, size: 16),
                    const SizedBox(width: 8),
                    Text(order.serviceName ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const Spacer(),
                    Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.textMedium, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(order.pickupAddress, style: const TextStyle(fontSize: 12, color: AppColors.textMedium), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.textMedium, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMM d, yyyy HH:mm').format(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),

                // Progress bar
                const SizedBox(height: 16),
                _buildProgressBar(order.status),

                if (order.deliveryBoyName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.motorcycle, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('Rider: ${order.deliveryBoyName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String status) {
    final steps = OrderStatus.all;
    final currentIdx = OrderStatus.stepIndex(status);
    return Row(
      children: steps.asMap().entries.map((e) {
        final done = e.key <= currentIdx;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
              if (e.key < steps.length - 1)
                Expanded(child: Container(height: 2, color: e.key < currentIdx ? AppColors.primary : AppColors.border)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
