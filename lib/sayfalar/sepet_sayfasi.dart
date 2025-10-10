import 'package:flutter/material.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';
import '../widgets/error_handler.dart';
import '../widgets/recommended_products.dart';
import 'urun_detay_sayfasi.dart';

class SepetSayfasi extends StatefulWidget {
  final List<Product> cartProducts;
  final Function(Product)? onRemoveFromCart;
  final Function(Product, int)? onUpdateQuantity;
  final Function(List<Product>)? onPlaceOrder;
  final List<Product>? favoriteProducts;
  final Function(Product, {bool showMessage})? onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;

  const SepetSayfasi({
    super.key, 
    required this.cartProducts,
    this.onRemoveFromCart,
    this.onUpdateQuantity,
    this.onPlaceOrder,
    this.favoriteProducts,
    this.onFavoriteToggle,
    this.onAddToCart,
  });

  @override
  State<SepetSayfasi> createState() => _SepetSayfasiState();
}

class _SepetSayfasiState extends State<SepetSayfasi> {
  @override
  void didUpdateWidget(SepetSayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sepet ürünleri değiştiğinde UI'ı güncelle
    if (widget.cartProducts.length != oldWidget.cartProducts.length ||
        widget.cartProducts != oldWidget.cartProducts) {
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    final total = widget.cartProducts.fold(0.0, (sum, p) => sum + p.totalPrice);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sepetim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
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
              colors: [Colors.green[50]!, Colors.grey[50]!],
            ),
          ),
        child: widget.cartProducts.isEmpty
            ? Column(
                children: [
                  // Boş sepet mesajı
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Sepetiniz boş',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ürünleri sepete ekleyerek alışverişe başlayın',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Önerilen ürünler (boş sepet durumunda da göster)
                  RecommendedProducts(
                      products: _getRecommendedProducts(),
                      onAddToCart: _addToCart,
                      onToggleFavorite: _toggleFavorite,
                      favoriteProducts: widget.favoriteProducts,
                    ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Sepet ürünleri
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.cartProducts.length,
                          itemBuilder: (context, index) {
                            final urun = widget.cartProducts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UrunDetaySayfasi(
                                      product: urun,
                                      isFavorite: false,
                                      inCart: true,
                                      onFavoriteToggle: (product) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${product.name} favorilerden çıkarıldı')),
                                        );
                                      },
                                      onAddToCart: (product) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${product.name} zaten sepette')),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.all(8),
                                elevation: 6,
                                shadowColor: Colors.green.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white, Colors.green[50]!],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Ürün resmi
                                        OptimizedImage(
                                          imageUrl: urun.imageUrl,
                                          width: isSmallScreen ? 60 : 80,
                                          height: isSmallScreen ? 60 : 80,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        const SizedBox(width: 12),
                                        // Ürün bilgileri
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                urun.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${urun.price.toStringAsFixed(2)} TL',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              // Miktar kontrolü
                                              Row(
                                                children: [
                                                  // Miktar azaltma
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (urun.quantity > 1) {
                                                        widget.onUpdateQuantity?.call(urun, urun.quantity - 1);
                                                      } else {
                                                        widget.onRemoveFromCart?.call(urun);
                                                      }
                                                    },
                                                    child: Container(
                                                      width: isSmallScreen ? 28 : 32,
                                                      height: isSmallScreen ? 28 : 32,
                                                      decoration: BoxDecoration(
                                                        color: urun.quantity > 1 ? Colors.orange[100] : Colors.red[100],
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Icon(
                                                        urun.quantity > 1 ? Icons.remove : Icons.delete,
                                                        color: urun.quantity > 1 ? Colors.orange[700] : Colors.red[700],
                                                        size: isSmallScreen ? 14 : 18,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Miktar gösterimi
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${urun.quantity}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: isSmallScreen ? 14 : 16,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Miktar artırma
                                                  GestureDetector(
                                                    onTap: () {
                                                      widget.onUpdateQuantity?.call(urun, urun.quantity + 1);
                                                    },
                                                    child: Container(
                                                      width: isSmallScreen ? 28 : 32,
                                                      height: isSmallScreen ? 28 : 32,
                                                      decoration: BoxDecoration(
                                                        color: Colors.green[100],
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        color: Colors.green[700],
                                                        size: isSmallScreen ? 14 : 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Toplam fiyat
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${urun.totalPrice.toStringAsFixed(2)} TL',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 14 : 16,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (urun.quantity > 1)
                                              Text(
                                                '${urun.quantity} x ${urun.price.toStringAsFixed(2)} TL',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          ),
                          
                          // Önerilen ürünler
                          RecommendedProducts(
                              products: _getRecommendedProducts(),
                              onAddToCart: _addToCart,
                              onToggleFavorite: _toggleFavorite,
                              favoriteProducts: widget.favoriteProducts,
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sepet özeti ve sipariş butonu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Sepet özeti
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sepet Özeti',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${widget.cartProducts.length} ürün',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Toplam Miktar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${widget.cartProducts.fold(0, (sum, p) => sum + p.quantity)} adet',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        // Toplam fiyat ve sipariş butonu
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${total.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                try {
                                  if (widget.cartProducts.isEmpty) {
                                    ErrorHandler.showError(context, 'Sepetiniz boş');
                                    return;
                                  }
                                  
                                  widget.onPlaceOrder?.call(widget.cartProducts);
                                  ErrorHandler.showSuccess(context, 'Siparişiniz başarıyla verildi!');
                                } catch (e) {
                                  ErrorHandler.showError(context, 'Sipariş verilirken hata oluştu');
                                }
                              },
                              icon: const Icon(Icons.shopping_bag),
                              label: const Text('Sipariş Ver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  List<Product> _getRecommendedProducts() {
    // Örnek önerilen ürünler
    return [
      Product(
        name: 'Önerilen Ürün 1',
        price: 299.99,
        imageUrl: 'assets/images/set.jpeg',
        description: 'Önerilen ürün açıklaması',
        quantity: 1,
      ),
      Product(
        name: 'Önerilen Ürün 2',
        price: 199.99,
        imageUrl: 'assets/images/telefon_tutucu.jpeg',
        description: 'Önerilen ürün açıklaması',
        quantity: 1,
      ),
      Product(
        name: 'Önerilen Ürün 3',
        price: 399.99,
        imageUrl: 'assets/images/areon_arac_kokusu.jpeg',
        description: 'Önerilen ürün açıklaması',
        quantity: 1,
      ),
    ];
  }

  void _addToCart(Product product) {
    widget.onAddToCart!(product, showMessage: false);
  }

  void _toggleFavorite(Product product) {
    widget.onFavoriteToggle!(product, showMessage: false);
  }
}