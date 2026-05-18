class DeliveryOrder {
  final int id;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final double totalAmount;
  final String? customerName;
  final String? customerPhone;
  final String? serviceName;
  final String paymentMethod;
  final DateTime createdAt;

  DeliveryOrder({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalAmount,
    this.customerName,
    this.customerPhone,
    this.serviceName,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) => DeliveryOrder(
    id: json['id'] ?? 0,
    status: json['status'] ?? 'assigned',
    pickupAddress: json['pickup_address'] ?? '',
    deliveryAddress: json['delivery_address'] ?? '',
    totalAmount: (json['total_amount'] ?? 0).toDouble(),
    customerName: json['customer_name'],
    customerPhone: json['customer_phone'],
    serviceName: json['service_name'],
    paymentMethod: json['payment_method'] ?? 'cash',
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}
