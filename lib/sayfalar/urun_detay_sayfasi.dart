import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../model/product.dart';
import '../model/product_review.dart';
import '../model/collection.dart';
import '../services/review_service.dart';
import '../services/collection_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/star_rating.dart';
import '../widgets/review_form.dart';
import '../widgets/review_list.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final Product product;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final bool forceHasPurchased; // Siparişlerden gelindiğinde true yapılacak

  const UrunDetaySayfasi({
    super.key,
    required this.product,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.favoriteProducts,
    required this.cartProducts,
    this.forceHasPurchased = false, // Varsayılan false
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  List<ProductReview> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  bool _reviewsLoaded = false; // İlk yükleme tamamlandı mı?
  bool _isRefreshingReviews = false; // Yorumlar şu an yenileniyor mu? (sonsuz döngü önlemek için)
  ProductReview? _userReview;
  List<Collection> _collections = [];
  bool _isLoadingCollections = false;
  bool _hasPurchased = false;
  bool _isCheckingPurchase = true;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadCollections();
    
    // Eğer siparişlerden gelindiğinde forceHasPurchased = true ise,
    // direkt hasPurchased = true yap ve kontrol atla
    if (widget.forceHasPurchased) {
      _hasPurchased = true;
      _isCheckingPurchase = false;
      debugPrint('✓ Siparişlerden gelindi - hasPurchased otomatik true yapıldı');
    } else {
      _checkPurchaseStatus();
    }
  }
  
  Future<void> _checkPurchaseStatus() async {
    if (!mounted) return;
    
    setState(() => _isCheckingPurchase = true);
    try {
      final hasPurchased = await _checkIfUserPurchased();
      if (mounted) {
        setState(() {
          _hasPurchased = hasPurchased;
          _isCheckingPurchase = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPurchased = false;
          _isCheckingPurchase = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store ScaffoldMessenger reference safely
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  /// Safely shows a SnackBar, checking if widget is mounted and context is valid
  void _showSnackBar(SnackBar snackBar) {
    if (mounted && _scaffoldMessenger != null) {
      try {
        _scaffoldMessenger!.showSnackBar(snackBar);
      } catch (e) {
        // Context is deactivated, silently ignore
        debugPrint('Error showing snackbar: $e');
      }
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    
    // Eğer zaten yükleniyorsa, tekrar yükleme (sonsuz döngü önlemek için)
    if (_isRefreshingReviews) {
      debugPrint('⚠ Yorumlar zaten yükleniyor, yeni istek atlandı');
      return;
    }
    
    try {
      debugPrint('=== YORUMLAR YÜKLENİYOR (UrunDetaySayfasi) ===');
      
      // Check mounted before starting
      if (!mounted) return;
      
      // Refresh flag'ini set et
      _isRefreshingReviews = true;
      
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      // Source.server ile yükle (cache'i bypass et)
      final reviews = await ReviewService.getProductReviews(widget.product.id);
      
      // Check mounted after async operation
      if (!mounted) return;
      
      debugPrint('Yüklenen yorum sayısı: ${reviews.length}');
      
      // Her yorumu logla (debug için)
      for (var review in reviews) {
        debugPrint('  - Review ID: ${review.id}, User: ${review.userName}, Rating: ${review.rating}, Approved: ${review.isApproved}');
      }
      
      final user = FirebaseAuth.instance.currentUser;
      
      ProductReview? userReview;
      if (user != null) {
        debugPrint('Kullanıcı yorumu kontrol ediliyor...');
        userReview = await ReviewService.getUserReviewForProduct(widget.product.id, user.uid);
        if (!mounted) return;
        debugPrint('Kullanıcı yorumu: ${userReview != null ? "Var (ID: ${userReview.id})" : "Yok"}');
      }
      
      // Double-check mounted before setState
      if (!mounted) return;
      
      // Calculate values before setState
      final calculatedAverageRating = ProductReview.calculateAverageRating(reviews);
      
      // Final mounted check before setState
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = calculatedAverageRating;
          _totalReviews = reviews.length;
          _userReview = userReview;
          _isLoading = false;
          _reviewsLoaded = true; // İlk yükleme tamamlandı
          _isRefreshingReviews = false; // Yükleme tamamlandı
        });
        
        if (mounted) {
          debugPrint('✓ Yorumlar yüklendi: ${reviews.length} adet');
          debugPrint('  - Ortalama rating: $_averageRating');
          debugPrint('  - Toplam yorum: $_totalReviews');
          debugPrint('  - Kullanıcı yorumu: ${userReview != null ? "Var" : "Yok"}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Yorumlar yüklenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshingReviews = false; // Hata durumunda da flag'i sıfırla
        });
        _showSnackBar(
          SnackBar(content: Text('Yorumlar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _onReviewAdded() async {
    if (!mounted || _isRefreshingReviews) {
      debugPrint('⚠ onReviewAdded atlandı - zaten yükleniyor veya unmounted');
      return;
    }
    
    debugPrint('=== onReviewAdded CALLBACK ÇAĞRILDI (PROFESYONEL MOD) ===');
    
    // Önce kısa bir bekleme (Firestore'un işlemesi için)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isRefreshingReviews) return;
    
    debugPrint('Yorumlar yeniden yükleniyor...');
    
    // Yorumları yeniden yükle (flag kontrolü _loadReviews içinde yapılıyor)
    try {
      await _loadReviews();
    } catch (e) {
      debugPrint('İlk yükleme hatası: $e');
      // Hata olursa bir kere daha dene (sadece bir kere)
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted && !_isRefreshingReviews) {
        await _loadReviews();
      }
    }
    
    if (!mounted) return;
    
    // Kullanıcı yorumunu da yeniden kontrol et
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      try {
        debugPrint('Kullanıcı yorumu kontrol ediliyor...');
        final userReview = await ReviewService.getUserReviewForProduct(widget.product.id, user.uid);
        if (mounted) {
          setState(() {
            _userReview = userReview;
          });
          debugPrint('Kullanıcı yorumu: ${userReview != null ? "Bulundu ✓" : "Bulunamadı ✗"}');
        }
      } catch (e) {
        debugPrint('Kullanıcı yorumu yüklenirken hata: $e');
      }
    }
    
    if (mounted) {
      debugPrint('✓ Yorumlar güncellendi: ${_reviews.length} adet');
      debugPrint('✓ Ortalama rating: $_averageRating');
      debugPrint('✓ Toplam yorum: $_totalReviews');
    }
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;
    
    if (mounted) {
      setState(() => _isLoadingCollections = true);
    }
    
    try {
      final collections = await CollectionService().getUserCollections();
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
          _collections = collections;
          _isLoadingCollections = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        setState(() => _isLoadingCollections = false);
      }
    }
  }

  Future<void> _addToCollection(Collection collection) async {
    try {
      // Ürünün imageUrl'ini geçerek, eğer koleksiyon boşsa kapak fotoğrafı olarak ayarlansın
      await CollectionService().addProductToCollection(
        collection.id, 
        widget.product.id,
        productImageUrl: widget.product.imageUrl,
      );
      if (!mounted) return;
      
      _showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} ${collection.name} koleksiyonuna eklendi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddToCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koleksiyona Ekle'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _isLoadingCollections
              ? const Center(child: CircularProgressIndicator())
              : _collections.isEmpty
                  ? const Center(
                      child: Text('Henüz koleksiyonunuz yok.\nÖnce koleksiyon oluşturun.'),
                    )
                  : ListView.builder(
                      itemCount: _collections.length,
                      itemBuilder: (context, index) {
                        final collection = _collections[index];
                        return ListTile(
                          leading: const Icon(Icons.collections_bookmark),
                          title: Text(collection.name),
                          subtitle: Text(collection.description),
                          trailing: Text('${collection.productIds.length} ürün'),
                          onTap: () {
                            Navigator.pop(context);
                            _addToCollection(collection);
                          },
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkIfUserPurchased() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      // ReviewService kullanarak satın alma kontrolü yap
      return await ReviewService.hasUserPurchasedProduct(widget.product.id, user.uid);
    } catch (e) {
      debugPrint('Satın alma kontrolü yapılırken hata: $e');
      return false;
    }
  }

  /// Ürünü paylaş
  Future<void> _shareProduct() async {
    try {
      // Deep link URL'i oluştur - hem custom scheme hem de HTTP formatında
      // WhatsApp ve diğer uygulamalar HTTP/HTTPS linklerini tıklanabilir yapar
      final productId = widget.product.id;
      
      // HTTP formatında deep link (daha tıklanabilir)
      // Bu format WhatsApp, Telegram gibi uygulamalarda tıklanabilir
      final httpLink = 'https://tuning-app-789ce.web.app/product/$productId';
      
      // Custom scheme deep link (uygulama açıldığında kullanılacak)
      final customSchemeLink = 'tuningapp://product/$productId';
      
      // Paylaş metni - HTTP linki (daha tıklanabilir)
      // Uygulama yüklüyse otomatik olarak custom scheme'e yönlendirilecek
      final shareText = httpLink;
      
      debugPrint('Product ID: $productId');
      debugPrint('HTTP Link: $httpLink');
      debugPrint('Custom Scheme Link: $customSchemeLink');

      debugPrint('=== PAYLAŞMA BAŞLATILIYOR ===');
      debugPrint('Paylaş linki: $shareText');

      // Paylaş - en basit yöntem, hiçbir parametre olmadan
      ShareResult result;
      
      // Önce subject olmadan dene (daha güvenilir)
      try {
        debugPrint('Subject olmadan paylaşma deneniyor...');
        result = await Share.share(shareText);
        debugPrint('✓ Paylaşma başarılı (subject olmadan)');
        debugPrint('Paylaşma sonucu: ${result.toString()}');
        return; // Başarılı, çık
      } catch (error1) {
        debugPrint('✗ Subject olmadan paylaşma hatası: $error1');
        debugPrint('Hata tipi: ${error1.runtimeType}');
      }

      // Subject ile dene
      try {
        debugPrint('Subject ile paylaşma deneniyor...');
        result = await Share.share(shareText, subject: widget.product.name);
        debugPrint('✓ Paylaşma başarılı (subject ile)');
        debugPrint('Paylaşma sonucu: ${result.toString()}');
        return; // Başarılı, çık
      } catch (error2) {
        debugPrint('✗ Subject ile paylaşma hatası: $error2');
        debugPrint('Hata tipi: ${error2.runtimeType}');
        // Her iki yöntem de başarısız
        rethrow; // Exception'ı yukarı fırlat
      }
      
    } on PlatformException catch (e) {
      // Platform-specific hatalar
      debugPrint('=== PLATFORM EXCEPTION ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      
      if (mounted) {
        String errorMessage = 'Paylaşma yapılamadı';
        
        final message = (e.message ?? '').toLowerCase();
        final code = e.code.toLowerCase();
        
        if (code == 'share_error' || 
            message.contains('not found') ||
            message.contains('activitynotfound') ||
            message.contains('resolveactivity') ||
            message.contains('no activity') ||
            message.contains('no handler')) {
          errorMessage = 'Paylaşma uygulaması bulunamadı.\nLütfen cihazınızda en az bir paylaşma uygulaması olduğundan emin olun.';
        } else if (code == 'not_implemented') {
          errorMessage = 'Bu cihazda paylaşma özelliği desteklenmiyor';
        } else {
          errorMessage = 'Paylaşma hatası\n${e.message ?? e.code}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _shareProduct(),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Genel hatalar
      debugPrint('=== GENEL HATA ===');
      debugPrint('Hata: $e');
      debugPrint('Hata tipi: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Paylaşma yapılamadı';
        
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('activitynotfound') || 
            errorStr.contains('no activity found') ||
            errorStr.contains('resolveactivity') ||
            errorStr.contains('intent.resolveactivity') ||
            errorStr.contains('no handler')) {
          errorMessage = 'Paylaşma uygulaması bulunamadı.\nCihazınızda WhatsApp, Gmail veya benzeri bir paylaşma uygulaması yüklü olmalı.';
        } else if (errorStr.contains('permission')) {
          errorMessage = 'Paylaşma izni verilmedi';
        } else if (errorStr.contains('not implemented')) {
          errorMessage = 'Bu cihazda paylaşma özelliği desteklenmiyor';
        } else {
          errorMessage = 'Paylaşma hatası oluştu';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Teknik detay: ${e.toString().substring(0, e.toString().length > 80 ? 80 : e.toString().length)}...',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
              ],
            ),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () => _shareProduct(),
            ),
          ),
        );
      }
    }
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
      resizeToAvoidBottomInset: false, // Klavye performansı için
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
          // Paylaş butonu
          IconButton(
            onPressed: _shareProduct,
            icon: const Icon(
              Icons.share,
              color: Colors.white,
            ),
            tooltip: 'Ürünü Paylaş',
          ),
          // Koleksiyon butonu
          IconButton(
            onPressed: _showAddToCollectionDialog,
            icon: const Icon(
              Icons.collections_bookmark,
              color: Colors.white,
            ),
          ),
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
            mainAxisSize: MainAxisSize.min,
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
                  mainAxisSize: MainAxisSize.min,
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
                    
                    // Rating ve yorum sayısı (her zaman göster, sadece loading state'i göster)
                    Row(
                      children: [
                        // Yıldızlar - her zaman göster (flickering önlemek için)
                        StarRating(
                          rating: _reviewsLoaded ? _averageRating : widget.product.averageRating,
                          size: isSmallScreen ? 16 : 18,
                        ),
                        const SizedBox(width: 8),
                        // Rating metni - loading durumunda hafif opacity
                        Opacity(
                          opacity: _reviewsLoaded ? 1.0 : 0.6,
                          child: Text(
                            _reviewsLoaded 
                                ? '${_averageRating.toStringAsFixed(1)} (${_totalReviews} yorum)'
                                : '${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.reviewCount} yorum)',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Loading indicator (sadece güncelleme sırasında göster)
                        if (_isLoading && _reviewsLoaded) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: isSmallScreen ? 12 : 14,
                            height: isSmallScreen ? 12 : 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    
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
                    Column(
                      children: [
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
                        const SizedBox(height: 12),
                        // Koleksiyona ekle butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showAddToCollectionDialog,
                            icon: const Icon(Icons.collections_bookmark),
                            label: const Text('Koleksiyona Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[600],
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
                        Text(
                          _reviewsLoaded ? '$_totalReviews yorum' : '${widget.product.reviewCount} yorum',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Kullanıcı yorumu yoksa yorum ekleme formu, varsa düzenleme formu
                    if (FirebaseAuth.instance.currentUser != null)
                      if (_isCheckingPurchase)
                        const Center(child: CircularProgressIndicator())
                      else if (_userReview == null)
                        ReviewForm(
                          productId: widget.product.id,
                          onReviewAdded: _onReviewAdded,
                          hasPurchased: _hasPurchased,
                        )
                      else
                        // Yorum yapılmışsa düzenleme formu göster
                        ReviewForm(
                          productId: widget.product.id,
                          existingReview: _userReview,
                          onReviewAdded: _onReviewAdded,
                          hasPurchased: _hasPurchased,
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
                        key: ValueKey('reviews_${widget.product.id}_${_totalReviews}_${(_reviews.isNotEmpty && _reviews.length > 0) ? _reviews.first.id : "empty"}_${DateTime.now().millisecondsSinceEpoch ~/ 500}'), // 500ms bazlı key (daha hızlı güncelleme)
                        productId: widget.product.id,
                        reviews: _reviews, // Her zaman gönder (ReviewList kendi yükleyecek)
                        onReviewUpdated: () {
                          // Callback'i çağır ama sonsuz döngüyü önle
                          if (!_isRefreshingReviews && mounted) {
                            debugPrint('ReviewList onReviewUpdated callback çağrıldı - yorumlar yenilenecek');
                            // Debounce: 500ms bekle (çok sık çağrılmasını önle)
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted && !_isRefreshingReviews) {
                                _loadReviews();
                              }
                            });
                          } else {
                            debugPrint('⚠ ReviewList callback atlandı - zaten yükleniyor');
                          }
                        },
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