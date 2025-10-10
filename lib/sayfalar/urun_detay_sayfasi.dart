import 'package:flutter/material.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';

class UrunDetaySayfasi extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final bool inCart;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;

  const UrunDetaySayfasi({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.inCart,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: OptimizedImage(
                imageUrl: product.imageUrl,
                height: 200,
                width: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${product.price.toStringAsFixed(2)} ₺',
                style: const TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 16),
            Text(product.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(isFavorite ? 'Favoriden Çıkar' : 'Favoriye Ekle'),
                  onPressed: () {
                    onFavoriteToggle(product);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_shopping_cart),
                  label: Text(inCart ? 'Sepette' : 'Sepete Ekle'),
                  onPressed: () {
                    onAddToCart(product);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
