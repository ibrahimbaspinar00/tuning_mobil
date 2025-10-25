import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product.dart';
import '../model/product_review.dart';
import '../services/review_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/star_rating.dart';
import '../widgets/review_form.dart';
import '../widgets/review_list.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final Product product;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;

  const UrunDetaySayfasi({
    super.key,
    required this.product,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.favoriteProducts,
    required this.cartProducts,
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  List<ProductReview> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  ProductReview? _userReview;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);
      
      final reviews = await ReviewService.getProductReviews(widget.product.id);
      final user = FirebaseAuth.instance.currentUser;
      
      ProductReview? userReview;
      if (user != null) {
        userReview = await ReviewService.getUserReviewForProduct(widget.product.id, user.uid);
      }
      
      setState(() {
        _reviews = reviews;
        _averageRating = ProductReview.calculateAverageRating(reviews);
        _totalReviews = reviews.length;
        _userReview = userReview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorumlar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _onReviewAdded() async {
    await _loadReviews();
  }

  bool _checkIfUserPurchased() {
    // Bu fonksiyon gerçek uygulamada sipariş geçmişinden kontrol edilecek
    // Şimdilik demo amaçlı true döndürüyoruz
    return true; // Demo: Herkes yorum yapabilir
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favoriteProducts.any((p) => p.name == widget.product.name);
    final inCart = widget.cartProducts.any((p) => p.name == widget.product.name);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : isTablet ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Favori butonu
          IconButton(
            onPressed: () => widget.onFavoriteToggle(widget.product),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
          ),
          // Sepet butonu
          Stack(
            children: [
              IconButton(
                onPressed: () => widget.onAddToCart(widget.product),
                icon: Icon(
                  inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                  color: inCart ? Colors.green : Colors.white,
                ),
              ),
              if (inCart)
                Positioned(
                  right: 8,
                  top: 8,
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
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün resmi
              Container(
                height: isSmallScreen ? 250 : isTablet ? 300 : 350,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: OptimizedImage(
                    imageUrl: widget.product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Ürün bilgileri
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün adı
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : isTablet ? 22 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Fiyat
                    Text(
                      '${widget.product.price.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : isTablet ? 24 : 26,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Rating ve yorum sayısı
                    if (!_isLoading) ...[
                      Row(
                        children: [
                          StarRating(
                            rating: _averageRating,
                            size: isSmallScreen ? 16 : 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_averageRating.toStringAsFixed(1)} (${_totalReviews} yorum)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Açıklama
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Aksiyon butonları
                    Row(
                      children: [
                        // Favori butonu
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onFavoriteToggle(widget.product),
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            label: Text(
                              isFavorite ? 'Favorilerde' : 'Favorilere Ekle',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFavorite ? Colors.red[400] : Colors.grey[200],
                              foregroundColor: isFavorite ? Colors.white : Colors.grey[700],
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sepete ekle butonu
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onAddToCart(widget.product),
                            icon: Icon(
                              inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            label: Text(
                              inCart ? 'Sepette' : 'Sepete Ekle',
                              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart ? Colors.green[400] : Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Yorumlar bölümü
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yorumlar',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (!_isLoading)
                          Text(
                            '$_totalReviews yorum',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Kullanıcı yorumu yoksa yorum ekleme formu
                    if (_userReview == null && FirebaseAuth.instance.currentUser != null)
                      ReviewForm(
                        productId: widget.product.id,
                        onReviewAdded: _onReviewAdded,
                        hasPurchased: _checkIfUserPurchased(),
                      )
                    else if (FirebaseAuth.instance.currentUser == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Yorum yapmak için giriş yapın',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Yorum listesi
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_reviews.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz yorum yok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'İlk yorumu siz yapın!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ReviewList(
                        productId: widget.product.id,
                        reviews: _reviews,
                        onReviewUpdated: _loadReviews,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}