class OrderItem {
  final String itemName;
  final String gender;
  int quantity;
  final double price;

  OrderItem({
    required this.itemName,
    this.gender = 'unisex',
    this.quantity = 0,
    this.price = 2.0,
  });

  Map<String, dynamic> toJson() => {
    'item_name': itemName,
    'gender': gender,
    'quantity': quantity,
    'price': price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itemName: json['item_name'] ?? '',
    gender: json['gender'] ?? 'unisex',
    quantity: json['quantity'] ?? 0,
    price: (json['price'] ?? 2.0).toDouble(),
  );
}

class OrderModel {
  final int id;
  final int customerId;
  final int? deliveryBoyId;
  final int serviceId;
  final String status;
  final String pickupAddress;
  final String deliveryAddress;
  final double totalAmount;
  final String colorPreference;
  final String washingTemp;
  final bool useDryHeater;
  final bool useScentedDetergent;
  final bool useSoftener;
  final String? additionalNote;
  final String paymentMethod;
  final String? serviceName;
  final String? deliveryBoyName;
  final List<OrderItem> items;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerId,
    this.deliveryBoyId,
    required this.serviceId,
    required this.status,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalAmount,
    this.colorPreference = 'color',
    this.washingTemp = 'celsius',
    this.useDryHeater = false,
    this.useScentedDetergent = false,
    this.useSoftener = false,
    this.additionalNote,
    this.paymentMethod = 'cash',
    this.serviceName,
    this.deliveryBoyName,
    this.items = const [],
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] ?? 0,
    customerId: json['customer_id'] ?? 0,
    deliveryBoyId: json['delivery_boy_id'],
    serviceId: json['service_id'] ?? 0,
    status: json['status'] ?? 'pending',
    pickupAddress: json['pickup_address'] ?? '',
    deliveryAddress: json['delivery_address'] ?? '',
    totalAmount: (json['total_amount'] ?? 0).toDouble(),
    colorPreference: json['color_preference'] ?? 'color',
    washingTemp: json['washing_temp'] ?? 'celsius',
    useDryHeater: json['use_dry_heater'] == 1,
    useScentedDetergent: json['use_scented_detergent'] == 1,
    useSoftener: json['use_softener'] == 1,
    additionalNote: json['additional_note'],
    paymentMethod: json['payment_method'] ?? 'cash',
    serviceName: json['service_name'],
    deliveryBoyName: json['delivery_boy_name'],
    items: (json['items'] as List<dynamic>?)?.map((i) => OrderItem.fromJson(i)).toList() ?? [],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

class ServiceModel {
  final int id;
  final String name;
  final String description;
  final double pricePerItem;
  final String icon;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerItem,
    required this.icon,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    pricePerItem: (json['price_per_item'] ?? 2.0).toDouble(),
    icon: json['icon'] ?? '',
  );
}
