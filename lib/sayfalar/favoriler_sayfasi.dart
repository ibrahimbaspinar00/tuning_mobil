import 'package:flutter/material.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';
import '../widgets/animated_button.dart';
import '../widgets/error_handler.dart';
import '../utils/debounce.dart';
import '../widgets/recommended_products.dart';
import 'urun_detay_sayfasi.dart';

class FavorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final Function(Product, {bool showMessage}) onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final List<Product>? cartProducts;

  const FavorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.onFavoriteToggle,
    this.onAddToCart,
    this.cartProducts,
  });

  @override
  State<FavorilerSayfasi> createState() => _FavorilerSayfasiState();
}

class _FavorilerSayfasiState extends State<FavorilerSayfasi> {
  String _searchQuery = '';
  String _sortBy = 'name';
  late Debounce _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchDebounce = Debounce(milliseconds: 500);
  }

  @override
  void didUpdateWidget(FavorilerSayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Favori ürünler değiştiğinde UI'ı güncelle
    if (widget.favoriteProducts.length != oldWidget.favoriteProducts.length ||
        widget.favoriteProducts != oldWidget.favoriteProducts) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var products = widget.favoriteProducts;
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Sıralama
    if (_sortBy == 'name') {
      products.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'price') {
      products.sort((a, b) => a.price.compareTo(b.price));
    }
    
    return products;
  }


  @override
  Widget build(BuildContext context) {
    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    // Responsive boyutlar
    final cardPadding = isSmallScreen ? 6.0 : isTablet ? 8.0 : 12.0;
    final imageSize = isSmallScreen ? 45.0 : isTablet ? 55.0 : 70.0;
    final titleFontSize = isSmallScreen ? 11.0 : isTablet ? 13.0 : 15.0;
    final priceFontSize = isSmallScreen ? 9.0 : isTablet ? 11.0 : 13.0;
    final descFontSize = isSmallScreen ? 7.0 : isTablet ? 9.0 : 11.0;
    final buttonSize = isSmallScreen ? 28.0 : isTablet ? 32.0 : 36.0;
    final iconSize = isSmallScreen ? 12.0 : isTablet ? 14.0 : 18.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Favorilerim',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort,
              size: isSmallScreen ? 20 : 24,
            ),
            onPressed: () => _showSortDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red[50]!, Colors.grey[50]!],
            ),
          ),
          child: Column(
            children: [
              // Arama çubuğu
              Container(
                margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    _searchDebounce.run(() {
                      setState(() {
                        _searchQuery = value;
                      });
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Favori ürünlerinizde ara...',
                    hintStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.red,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: isSmallScreen ? 16 : 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                  ),
                ),
              ),
              
              // Ürün sayısı
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                          ? '${_filteredProducts.length} arama sonucu'
                          : '${widget.favoriteProducts.length} favori ürün',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : isTablet ? 14 : 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          try {
                            setState(() {
                              _searchQuery = '';
                            });
                            ErrorHandler.showSilentInfo(
                              context, 
                              'Arama temizlendi'
                            );
                          } catch (e) {
                            ErrorHandler.showError(
                              context, 
                              'Arama temizlenirken hata oluştu'
                            );
                          }
                        },
                        icon: Icon(
                          Icons.clear,
                          size: isSmallScreen ? 14 : 18,
                        ),
                        label: Text(
                          'Temizle',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red[600],
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 4 : 8),
              
              // Ürün listesi
              Expanded(
                child: _filteredProducts.isEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            // Boş favori mesajı
                            SizedBox(
                              height: isSmallScreen 
                                  ? screenHeight * 0.25 
                                  : isTablet 
                                      ? screenHeight * 0.3 
                                      : screenHeight * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty 
                                          ? Icons.search_off 
                                          : Icons.favorite_border,
                                      size: isSmallScreen ? 60 : isTablet ? 70 : 80,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: isSmallScreen ? 8 : 16),
                                    Text(
                                      _searchQuery.isNotEmpty 
                                          ? 'Arama sonucu bulunamadı' 
                                          : 'Henüz favori ürününüz yok',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : isTablet ? 16 : 18,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: isSmallScreen ? 4 : 8),
                                    Text(
                                      _searchQuery.isNotEmpty 
                                          ? 'Farklı anahtar kelimeler deneyin'
                                          : 'Beğendiğiniz ürünleri favorilere ekleyin',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : isTablet ? 12 : 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
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
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Favori ürünler
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final urun = _filteredProducts[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 2 : 4,
                                    horizontal: isSmallScreen ? 1 : 2,
                                  ),
                                  elevation: isSmallScreen ? 4 : 8,
                                  shadowColor: Colors.red.withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 12 : 20,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 12 : 20,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.white, Colors.red[50]!],
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UrunDetaySayfasi(
                                              product: urun,
                                              isFavorite: true,
                                              inCart: false,
                                              onFavoriteToggle: widget.onFavoriteToggle,
                                              onAddToCart: widget.onAddToCart ?? (product) {},
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 12 : 20,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(cardPadding),
                                        child: Row(
                                          children: [
                                            // Ürün resmi
                                            OptimizedImage(
                                              imageUrl: urun.imageUrl,
                                              width: imageSize,
                                              height: imageSize,
                                              borderRadius: BorderRadius.circular(
                                                isSmallScreen ? 8 : 12,
                                              ),
                                            ),
                                            SizedBox(width: isSmallScreen ? 6 : 8),
                                            
                                            // Ürün bilgileri
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    urun.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: titleFontSize,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: isSmallScreen ? 1 : 2),
                                                  Text(
                                                    '${urun.price.toStringAsFixed(2)} TL',
                                                    style: TextStyle(
                                                      color: Colors.red[700],
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: priceFontSize,
                                                    ),
                                                  ),
                                                  SizedBox(height: isSmallScreen ? 1 : 2),
                                                  Text(
                                                    urun.description,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: descFontSize,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Aksiyon butonları
                                            Column(
                                              children: [
                                                // Favori çıkar butonu
                                                AnimatedButton(
                                                  onPressed: () {
                                                    if (!mounted) return;
                                                    
                                                    try {
                                                      widget.onFavoriteToggle(urun);
                                                      ErrorHandler.showSilentInfo(
                                                        context, 
                                                        '${urun.name} favorilerden çıkarıldı'
                                                      );
                                                    } catch (e) {
                                                      ErrorHandler.showError(
                                                        context, 
                                                        'Favorilerden çıkarırken hata oluştu'
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    width: buttonSize,
                                                    height: buttonSize,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[100],
                                                      borderRadius: BorderRadius.circular(
                                                        isSmallScreen ? 6 : 8,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: Colors.red[700],
                                                      size: iconSize,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: isSmallScreen ? 2 : 4),
                                                
                                                // Sepete ekle butonu
                                                AnimatedButton(
                                                  onPressed: () {
                                                    if (!mounted) return;
                                                    
                                                    try {
                                                      widget.onAddToCart!(urun);
                                                      ErrorHandler.showSilentSuccess(
                                                        context, 
                                                        '${urun.name} sepete eklendi'
                                                      );
                                                    } catch (e) {
                                                      ErrorHandler.showError(
                                                        context, 
                                                        'Ürün sepete eklenirken hata oluştu'
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    width: buttonSize,
                                                    height: buttonSize,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[100],
                                                      borderRadius: BorderRadius.circular(
                                                        isSmallScreen ? 6 : 8,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.add_shopping_cart,
                                                      color: Colors.green[700],
                                                      size: iconSize,
                                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;
        
        return AlertDialog(
          title: Text(
            'Sıralama Seçenekleri',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(
                  'İsme Göre',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                value: 'name',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  try {
                    setState(() {
                      _sortBy = value!;
                    });
                    ErrorHandler.showSilentInfo(
                      context, 
                      'İsme göre sıralandı'
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ErrorHandler.showError(
                      context, 
                      'Sıralama değiştirilirken hata oluştu'
                    );
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(
                  'Fiyata Göre',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                value: 'price',
                groupValue: _sortBy,
                onChanged: (String? value) {
                  try {
                    setState(() {
                      _sortBy = value!;
                    });
                    ErrorHandler.showSilentInfo(
                      context, 
                      'Fiyata göre sıralandı'
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ErrorHandler.showError(
                      context, 
                      'Sıralama değiştirilirken hata oluştu'
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Kapat',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ],
        );
      },
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
    widget.onFavoriteToggle(product, showMessage: false);
  }
}