
enum OrderStatus {
  pending,    // Beklemede
  confirmed,  // Onaylandı
  shipped,    // Kargoya verildi
  delivered,  // Teslim edildi
  cancelled,  // İptal edildi
}

class Order {
  final String id;
  final List<Map<String, dynamic>> products;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;

  Order({
    required this.id,
    required this.products,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'pending',
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
  });

  // Toplam ürün sayısı
  int get totalItems => products.fold(0, (sum, product) => sum + (product['quantity'] as int? ?? 0));

  // Sipariş durumu metni
  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'confirmed':
        return 'Onaylandı';
      case 'shipped':
        return 'Kargoya Verildi';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // Sipariş durumu rengi
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'blue';
      case 'shipped':
        return 'purple';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }
}
