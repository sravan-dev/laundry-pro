import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'order_success_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final ServiceModel service;
  const PlaceOrderScreen({super.key, required this.service});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int _step = 0; // 0: items, 1: options, 2: addresses, 3: payment
  final _pageCtrl = PageController();

  // Items
  final List<OrderItem> _items = [
    OrderItem(itemName: 'T-Shirt', gender: 'Men'),
    OrderItem(itemName: 'Outer Wear', gender: 'Men'),
    OrderItem(itemName: 'Bottom', gender: 'Men'),
    OrderItem(itemName: 'Dresses', gender: 'Women'),
    OrderItem(itemName: 'Home', gender: 'unisex'),
    OrderItem(itemName: 'Other', gender: 'unisex'),
  ];

  // Options
  String _colorPref = 'color';
  String _washingTemp = 'celsius';
  bool _dryHeater = true;
  bool _scentedDetergent = true;
  bool _softener = true;
  final _noteCtrl = TextEditingController();

  // Addresses
  final _pickupCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();

  // Payment
  String _paymentMethod = 'cash';
  bool _loading = false;

  double get _total => _items.fold(0, (sum, i) => sum + (i.price * i.quantity));

  void _nextStep() {
    if (_step == 0) {
      final total = _items.fold(0, (s, i) => s + i.quantity);
      if (total == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one item'), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    if (_step == 2) {
      if (_pickupCtrl.text.isEmpty || _deliveryCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill both addresses'), backgroundColor: AppColors.error),
        );
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.post('customer/orders.php', {
        'service_id': widget.service.id,
        'pickup_address': _pickupCtrl.text.trim(),
        'delivery_address': _deliveryCtrl.text.trim(),
        'items': _items.where((i) => i.quantity > 0).map((i) => i.toJson()).toList(),
        'color_preference': _colorPref,
        'washing_temp': _washingTemp,
        'use_dry_heater': _dryHeater ? 1 : 0,
        'use_scented_detergent': _scentedDetergent ? 1 : 0,
        'use_softener': _softener ? 1 : 0,
        'additional_note': _noteCtrl.text.trim(),
        'payment_method': _paymentMethod,
      });
      if (res['success'] == true && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: int.tryParse(res['order_id'].toString()) ?? 0,
            total: (res['total'] as num).toDouble(),
          ),
        ));
      } else {
        throw Exception(res['error'] ?? 'Order failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Add Items', 'Options', 'Delivery', 'Payment'];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textDark),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
              _pageCtrl.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(widget.service.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: List.generate(steps.length, (i) {
                final done = i < _step;
                final active = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: done || active ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: done || active ? AppColors.primary : AppColors.border, width: 1.5),
                            ),
                            child: Center(
                              child: done
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : Text('${i+1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                    color: active ? Colors.white : AppColors.textLight)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(steps[i], style: TextStyle(fontSize: 9, color: active ? AppColors.primary : AppColors.textLight, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (i < steps.length - 1)
                        Expanded(child: Container(height: 1.5, margin: const EdgeInsets.only(bottom: 16),
                          color: i < _step ? AppColors.primary : AppColors.border)),
                    ],
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildItemsPage(),
                _buildOptionsPage(),
                _buildAddressPage(),
                _buildPaymentPage(),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                if (_total > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                      Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: AppButton(
                    label: _step == 3 ? 'Place Order' : 'Continue',
                    onPressed: _nextStep,
                    isLoading: _loading,
                    icon: _step == 3 ? Icons.check_circle_outline : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Select Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Text('Service: ${widget.service.name} — \$${widget.service.pricePerItem.toStringAsFixed(2)}/item',
          style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const SizedBox(height: 16),
        ..._items.asMap().entries.map((e) => _buildItemRow(e.key, e.value)),
      ],
    );
  }

  Widget _buildItemRow(int index, OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.quantity > 0 ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.checkroom, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Row(
                  children: [
                    Text('\$${item.price.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    // Gender selector
                    _genderChip(index, 'Men'),
                    const SizedBox(width: 4),
                    _genderChip(index, 'Women'),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _qtyBtn(Icons.remove, () {
                if (item.quantity > 0) setState(() => item.quantity--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark)),
              ),
              _qtyBtn(Icons.add, () => setState(() => item.quantity++)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(int index, String gender) {
    final selected = _items[index].gender == gender;
    return GestureDetector(
      onTap: () => setState(() => _items[index] = OrderItem(
        itemName: _items[index].itemName, gender: gender,
        quantity: _items[index].quantity, price: _items[index].price,
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(gender, style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textLight, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildOptionsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionCard('Color Preference', [
          _radioTile('Color Clothes', 'color', _colorPref, (v) => setState(() => _colorPref = v!)),
          _radioTile('White Clothes', 'white', _colorPref, (v) => setState(() => _colorPref = v!)),
        ]),
        const SizedBox(height: 14),
        _sectionCard('Washing Temperature', [
          _radioTile('Celsius', 'celsius', _washingTemp, (v) => setState(() => _washingTemp = v!)),
          _radioTile('Fahrenheit', 'fahrenheit', _washingTemp, (v) => setState(() => _washingTemp = v!)),
        ]),
        const SizedBox(height: 14),
        _sectionCard('Other Preferences', [
          _switchTile('Dry Heater', _dryHeater, (v) => setState(() => _dryHeater = v)),
          _switchTile('Scented Detergent', _scentedDetergent, (v) => setState(() => _scentedDetergent = v)),
          _switchTile('Use Softener', _softener, (v) => setState(() => _softener = v)),
        ]),
        const SizedBox(height: 14),
        _sectionCard('Additional Note', [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special instructions...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _radioTile(String label, String value, String groupValue, void Function(String?) onChanged) {
    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _switchTile(String label, bool value, void Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildAddressPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Delivery Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Pickup Address',
          hint: '15 Hickory Lane, Silver Spring DC',
          controller: _pickupCtrl,
          prefixIcon: Icons.location_on,
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Delivery Address',
          hint: '15 Hickory Lane, Silver Spring DC',
          controller: _deliveryCtrl,
          prefixIcon: Icons.location_on_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            if (_pickupCtrl.text.isNotEmpty) {
              _deliveryCtrl.text = _pickupCtrl.text;
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sync, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Same as pickup address', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPage() {
    final methods = [
      {'key': 'cash', 'label': 'Cash on Delivery', 'icon': Icons.money},
      {'key': 'card', 'label': 'Credit/Debit Card', 'icon': Icons.credit_card},
      {'key': 'wallet', 'label': 'Digital Wallet', 'icon': Icons.account_balance_wallet_outlined},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 20),
        ...methods.map((m) {
          final selected = _paymentMethod == m['key'];
          return GestureDetector(
            onTap: () => setState(() => _paymentMethod = m['key'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(m['icon'] as IconData, color: selected ? AppColors.primary : AppColors.textMedium),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(m['label'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textDark))),
                  if (selected) const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        // Order summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
              const SizedBox(height: 12),
              ..._items.where((i) => i.quantity > 0).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${i.itemName} (${i.gender}) x${i.quantity}', style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                    Text('\$${(i.price * i.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('\$${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
