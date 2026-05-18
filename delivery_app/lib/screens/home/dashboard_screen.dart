import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import '../order/order_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DeliveryUser? _user;
  Map<String, List<DeliveryOrder>> _ordersByStatus = {};
  bool _loading = true;
  bool _silentRefreshing = false; // background refresh without spinner
  DateTime? _lastRefreshed;
  Timer? _autoRefreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

  final _tabs = ['Active', 'Delivered', 'All'];
  final _tabStatuses = [
    ['assigned', 'picked_up', 'washing', 'ready', 'out_for_delivery'],
    ['delivered'],
    null,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _load();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) _silentLoad();
    });
  }

  // Full load (shows spinner on first load)
  Future<void> _load() async {
    if (!_loading) setState(() => _silentRefreshing = true);
    _user = await AuthService.getSavedUser();
    if (_user == null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeliveryLoginScreen()));
      return;
    }
    try {
      final res = await ApiService.get('delivery/orders.php');
      final orders = (res['data'] as List).map((o) => DeliveryOrder.fromJson(o)).toList();
      if (mounted) {
        setState(() {
          _ordersByStatus = {'all': orders};
          _loading = false;
          _silentRefreshing = false;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _silentRefreshing = false; });
    }
  }

  // Background refresh — no spinner, just updates data quietly
  Future<void> _silentLoad() async {
    if (_silentRefreshing) return;
    setState(() => _silentRefreshing = true);
    try {
      final res = await ApiService.get('delivery/orders.php');
      final orders = (res['data'] as List).map((o) => DeliveryOrder.fromJson(o)).toList();
      if (mounted) {
        setState(() {
          _ordersByStatus = {'all': orders};
          _silentRefreshing = false;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _silentRefreshing = false);
    }
  }

  List<DeliveryOrder> _filtered(List<String>? statuses) {
    final all = _ordersByStatus['all'] ?? [];
    if (statuses == null) return all;
    return all.where((o) => statuses.contains(o.status)).toList();
  }

  String get _lastRefreshedText {
    if (_lastRefreshed == null) return '';
    final diff = DateTime.now().difference(_lastRefreshed!);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildRefreshBar(),
          _buildTabs(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: _tabStatuses.asMap().entries.map((e) {
                      final orders = _filtered(e.value);
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: orders.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: orders.length,
                                itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
                              ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Auto-refresh countdown indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _silentRefreshing ? AppColors.orange : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _silentRefreshing
                  ? 'Refreshing...'
                  : 'Auto-refresh every 30s${_lastRefreshed != null ? ' · $_lastRefreshedText' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
            ),
          ),
          // Manual refresh button
          GestureDetector(
            onTap: _silentRefreshing ? null : _silentLoad,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _silentRefreshing ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Text('Refresh', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final all = _ordersByStatus['all'] ?? [];
    final active = all.where((o) => o.status != 'delivered').length;
    final delivered = all.where((o) => o.status == 'delivered').length;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Good day, Rider!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(_user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              // Refresh icon in header
              GestureDetector(
                onTap: _silentRefreshing ? null : _silentLoad,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: _silentRefreshing
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  _autoRefreshTimer?.cancel();
                  await AuthService.logout();
                  if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeliveryLoginScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip('$active', 'Active', Icons.pending_actions),
              const SizedBox(width: 12),
              _statChip('$delivered', 'Delivered', Icons.check_circle_outline),
              const SizedBox(width: 12),
              _statChip('${all.length}', 'Total', Icons.list_alt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: 200,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.inbox, color: AppColors.textLight, size: 48),
            const SizedBox(height: 12),
            const Text('No orders', style: TextStyle(color: AppColors.textMedium, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Pull down to refresh', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          ]),
        ),
      ],
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    final color = OrderStatus.color(order.status);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ).then((_) => _silentLoad()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.receipt_long, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text('Order #${order.id}', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(OrderStatus.label(order.status), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.textMedium),
                      const SizedBox(width: 6),
                      Expanded(child: Text(order.customerName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark))),
                      Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _addressRow(Icons.radio_button_on, 'Pickup', order.pickupAddress, Colors.green),
                  const SizedBox(height: 4),
                  _addressRow(Icons.location_on, 'Deliver', order.deliveryAddress, Colors.red),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.payment, size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(order.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                      ]),
                      Text(DateFormat('MMM d, HH:mm').format(order.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressRow(IconData icon, String label, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        Expanded(child: Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textMedium), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
