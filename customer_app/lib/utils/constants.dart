import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF22C55E);
  static const primaryDark = Color(0xFF16A34A);
  static const primaryLight = Color(0xFFBBF7D0);
  static const primarySurface = Color(0xFFF0FDF4);
  static const background = Color(0xFFF8FAFC);
  static const white = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMedium = Color(0xFF64748B);
  static const textLight = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const error = Color(0xFFEF4444);
}

class AppConfig {
  // Change this to your local server URL
  static const baseUrl = 'https://laundry.hellosravan.in/api';
}

class OrderStatus {
  static const pending = 'pending';
  static const assigned = 'assigned';
  static const pickedUp = 'picked_up';
  static const washing = 'washing';
  static const ready = 'ready';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';

  static String label(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) =>
      w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)
    ).join(' ');
  }

  static Color color(String status) {
    switch (status) {
      case pending: return const Color(0xFFF59E0B);
      case assigned: return const Color(0xFF3B82F6);
      case pickedUp: return const Color(0xFF8B5CF6);
      case washing: return const Color(0xFF6366F1);
      case ready: return const Color(0xFF14B8A6);
      case outForDelivery: return const Color(0xFFF97316);
      case delivered: return AppColors.primary;
      default: return AppColors.textMedium;
    }
  }

  static List<String> get all => [pending, assigned, pickedUp, washing, ready, outForDelivery, delivered];

  static int stepIndex(String status) => all.indexOf(status);
}
