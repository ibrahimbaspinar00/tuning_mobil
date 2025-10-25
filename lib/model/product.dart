class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  final String category;
  final int stock;
  int quantity; // Sepetteki miktar

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.stock,
    this.quantity = 1,
  });

  // Toplam fiyat hesaplama
  double get totalPrice {
    if (price.isNaN || quantity.isNaN || price.isInfinite || quantity.isInfinite) {
      return 0.0;
    }
    return price * quantity;
  }

  // Ürün kopyalama (miktar ile)
  Product copyWith({int? quantity}) {
    return Product(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      description: description,
      category: category,
      stock: stock,
      quantity: quantity ?? this.quantity,
    );
  }

  static List<Product>? get dummyProducts => null;
}
