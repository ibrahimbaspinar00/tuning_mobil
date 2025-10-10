class Product {
  final String name;
  final double price;
  final String imageUrl;
  final String description;
  int quantity; // Sepetteki miktar

  Product({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
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
      name: name,
      price: price,
      imageUrl: imageUrl,
      description: description,
      quantity: quantity ?? this.quantity,
    );
  }

  static List<Product>? get dummyProducts => null;
}
