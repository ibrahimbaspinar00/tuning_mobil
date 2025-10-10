import 'package:flutter/material.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';
import '../widgets/animated_button.dart';
import 'urun_detay_sayfasi.dart';

class UrunlerSayfasi extends StatefulWidget {
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final List<Product> dummyProducts;

  const UrunlerSayfasi({
    super.key,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.dummyProducts,
  });

  @override
  State<UrunlerSayfasi> createState() => _UrunlerSayfasiState();
}

class _UrunlerSayfasiState extends State<UrunlerSayfasi> with AutomaticKeepAliveClientMixin {
  late List<Product> _favorites;
  late List<Product> _cart;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _favorites = List<Product>.from(widget.favoriteProducts);
    _cart = List<Product>.from(widget.cartProducts);
  }

  void _toggleFavorite(Product product) {
    if (!mounted) return;
    setState(() {
      if (_favorites.contains(product)) {
        _favorites.remove(product);
      } else {
        _favorites.add(product);
      }
      widget.onFavoriteToggle(product);
    });
  }

  void _addToCart(Product product) {
    if (!mounted) return;
    setState(() {
      // Aynı ürünü bul
      final existingIndex = _cart.indexWhere((p) => p.name == product.name);
      
      if (existingIndex != -1) {
        // Ürün zaten sepette, miktarını artır
        _cart[existingIndex].quantity++;
      } else {
        // Yeni ürün ekle
        _cart.add(product.copyWith(quantity: 1));
      }
      widget.onAddToCart(product);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Araç Aksesuarları', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.grey[50]!],
            ),
          ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView.builder(
            itemCount: widget.dummyProducts.length,
            itemBuilder: (context, index) {
              final product = widget.dummyProducts[index];
              final isFavorite = _favorites.contains(product);
              final inCart = _cart.any((p) => p.name == product.name);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 8,
                shadowColor: Colors.blue.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey[50]!],
                    ),
                  ),
                  child: ListTile(
                    leading: OptimizedImage(
                      imageUrl: product.imageUrl,
                      width: 60,
                      height: 60,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${product.price.toStringAsFixed(2)} ₺\n${product.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        AnimatedButton(
                          onPressed: () => _toggleFavorite(product),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey[600],
                                size: isFavorite ? 28 : 24,
                              ),
                              onPressed: null, // AnimatedButton handles this
                            ),
                          ),
                        ),
                        AnimatedButton(
                          onPressed: () => _addToCart(product),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Stack(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                    color: inCart ? Colors.green : Colors.blue[600],
                                    size: inCart ? 28 : 24,
                                  ),
                                  onPressed: null, // AnimatedButton handles this
                                ),
                                if (inCart)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_cart.firstWhere((p) => p.name == product.name, orElse: () => product).quantity}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UrunDetaySayfasi(
                            product: product,
                            isFavorite: isFavorite,
                            inCart: inCart,
                            onFavoriteToggle: _toggleFavorite,
                            onAddToCart: _addToCart,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}
