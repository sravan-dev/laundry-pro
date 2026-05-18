import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/app_button.dart';
import '../home/home_screen.dart';
import 'order_history_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final int orderId;
  final double total;

  const OrderSuccessScreen({super.key, required this.orderId, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.primary, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('Order #$orderId has been placed successfully.\nWe\'ll pick it up soon!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.5)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Order #', '#$orderId'),
                    _divider(),
                    _stat('Total', '\$${total.toStringAsFixed(2)}'),
                    _divider(),
                    _stat('Status', 'Pending'),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Track Order',
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                icon: Icons.track_changes,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Back to Home',
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
                outline: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
    ],
  );

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);
}
