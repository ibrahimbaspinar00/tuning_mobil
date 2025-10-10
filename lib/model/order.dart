import 'product.dart';

enum OrderStatus {
  pending,    // Beklemede
  confirmed,  // Onaylandı
  shipped,    // Kargoya verildi
  delivered,  // Teslim edildi
  cancelled,  // İptal edildi
}

class Order {
  final String id;
  final List<Product> products;
  final double totalAmount;
  final DateTime orderDate;
  final OrderStatus status;
  final String customerName;
  final String customerEmail;
  final String shippingAddress;

  Order({
    required this.id,
    required this.products,
    required this.totalAmount,
    required this.orderDate,
    this.status = OrderStatus.pending,
    required this.customerName,
    required this.customerEmail,
    required this.shippingAddress,
  });

  // Toplam ürün sayısı
  int get totalItems => products.fold(0, (sum, product) => sum + product.quantity);

  // Sipariş durumu metni
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.shipped:
        return 'Kargoya Verildi';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  // Sipariş durumu rengi
  String get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return 'orange';
      case OrderStatus.confirmed:
        return 'blue';
      case OrderStatus.shipped:
        return 'purple';
      case OrderStatus.delivered:
        return 'green';
      case OrderStatus.cancelled:
        return 'red';
    }
  }
}
