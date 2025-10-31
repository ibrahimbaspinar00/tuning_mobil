import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/admin_service.dart' as admin;
import '../model/product.dart';
import '../model/collection.dart';
import '../services/collection_service.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import 'urun_detay_sayfasi.dart';

class ListelerimSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final VoidCallback? onNavigateToMainPage;

  const ListelerimSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onNavigateToMainPage,
  });

  @override
  State<ListelerimSayfasi> createState() => _ListelerimSayfasiState();
}

class _ListelerimSayfasiState extends State<ListelerimSayfasi>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Collection> _collections = [];
  bool _isLoading = true;
  // Beğendiklerim sekmesi için arama ve sıralama
  String _favSearchQuery = '';
  String _favSortBy = 'name_asc';
  String _favFilterCategory = 'all';
  double _favMinPrice = 0;
  double _favMaxPrice = 10000; // name_asc, price_asc, price_desc
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Tab değiştiğinde FloatingActionButton'u güncelle
      });
    });
    _loadCollections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store ScaffoldMessenger reference safely
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _loadCollections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print('Debug: Loading collections...');
      final collections = await CollectionService().getUserCollections()
          .timeout(const Duration(seconds: 10));
      print('Debug: Loaded ${collections.length} collections');
      
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
      
      // Demo koleksiyonlar kaldırıldı
    } catch (e) {
      print('Debug: Error loading collections: $e');
      if (!mounted) return;
      
      // Hata durumunda boş liste göster
      setState(() {
        _collections = [];
        _isLoading = false;
      });
      _showSnackBar(
        SnackBar(
          content: Text('Listeler yüklenirken hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  void _showCreateCollectionDialog({Collection? existingCollection}) {
    final nameController = TextEditingController(text: existingCollection?.name ?? '');
    final descriptionController = TextEditingController(text: existingCollection?.description ?? '');
    final bool isEditing = existingCollection != null;
    String? coverImageUrl = existingCollection?.coverImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Listeyi Düzenle' : 'Yeni Liste'),
            content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.text,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Liste Adı',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    // Sadece gerekli durumlarda rebuild
                  },
                ),
                // Kapak fotoğrafı sadece düzenleme modunda veya mevcut fotoğraf varsa göster
                if (isEditing && (coverImageUrl != null && coverImageUrl.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: OptimizedImage(imageUrl: coverImageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kapak fotoğrafı: İlk eklenen ürünün fotoğrafı otomatik olarak kapak fotoğrafı olacak',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ] else if (!isEditing) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'İlk eklenen ürünün fotoğrafı otomatik olarak kapak fotoğrafı olacak',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: descriptionController,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.multiline,
                  enableSuggestions: false,
                  autocorrect: false,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    // Sadece gerekli durumlarda rebuild
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                final name = nameController.text.trim();
                final desc = descriptionController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen liste adı girin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() => isUploading = true);

                try {
                  // Kapak fotoğrafı artık otomatik olarak ilk ürünün fotoğrafı olacak
                  // Sadece düzenleme modunda mevcut coverImageUrl'i koruyoruz
                  String? finalCoverUrl = isEditing ? coverImageUrl : null;

                  bool success = false;
                  if (isEditing) {
                    await _updateCollection(
                      existingCollection,
                      name,
                      desc,
                      coverImageUrl: finalCoverUrl,
                      showSnackBar: false, // Dialog içinde gösterilmeyecek, ana widget'ta gösterilecek
                    );
                    success = true;
                  } else {
                    await _createCollection(
                      name,
                      desc,
                      coverImageUrl: finalCoverUrl,
                      showSnackBar: false, // Dialog içinde gösterilmeyecek, ana widget'ta gösterilecek
                    );
                    success = true;
                  }
                  
                  // İşlem başarılı olduysa hemen dialog'u kapat
                  if (success) {
                    setState(() => isUploading = false);
                    // Dialog'u hemen kapat - mounted kontrolü ile
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    // Ana widget context'inde işlemleri yap
                    Future.microtask(() {
                      if (!mounted) return;
                      // Liste yeniden yüklensin - ana widget context'inde
                      _loadCollections();
                      _showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? 'Liste güncellendi!' : 'Liste başarıyla oluşturuldu!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                    return; // İşlem bitti, çık
                  }
                } catch (e) {
                  print('Debug: İşlem hatası: $e');
                  print('Debug: Hata tipi: ${e.runtimeType}');
                  // Hata durumunda loading'i kapat ama dialog'u açık tut
                  setState(() => isUploading = false);
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  } catch (_) {
                    // Context deaktif, ana widget'ta göster
                    Future.microtask(() {
                      _showSnackBar(
                        SnackBar(
                          content: Text('Hata: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    });
                  }
                }
              },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEditing ? 'Güncelle' : 'Oluştur'),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _updateCollection(
    Collection collection,
    String name,
    String description, {
    String? coverImageUrl,
    bool showSnackBar = true,
  }) async {
    try {
      final updatedCollection = Collection(
        id: collection.id,
        name: name,
        description: description,
        userId: collection.userId,
        productIds: collection.productIds,
        createdAt: collection.createdAt,
        updatedAt: DateTime.now(),
        coverImageUrl: coverImageUrl ?? collection.coverImageUrl,
      );
      
      await CollectionService().updateCollection(updatedCollection);
      if (!mounted) return;
      
      // setState ana widget'ta yapılacak - bu metod dialog context'inde çalışıyor
      
      if (!mounted) return;
      if (showSnackBar) {
        _showSnackBar(
          const SnackBar(
            content: Text('Koleksiyon güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (showSnackBar) {
        _showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        rethrow; // Dialog içinde handle etmek için
      }
    }
  }

  Future<void> _createCollection(
    String name,
    String description, {
    String? coverImageUrl,
    bool showSnackBar = true,
  }) async {
    try {
      // Debug: Check user authentication
      final user = FirebaseAuth.instance.currentUser;
      print('Debug: Current user: ${user?.uid}');
      
      final collection = Collection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        userId: user?.uid ?? '',
        productIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImageUrl: coverImageUrl,
      );

      print('Debug: Creating collection: ${collection.name}');
      await CollectionService().createCollection(collection);
      print('Debug: Collection created successfully');
      
      if (!mounted) return;
      
      // setState ana widget'ta yapılmalı - bu metod dialog context'inde çalışıyor
      // Dialog kapanınca ana widget'ta state güncellenecek
      
      if (!mounted) return;
      if (showSnackBar) {
        _showSnackBar(
          const SnackBar(
            content: Text('Koleksiyon oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Debug: Error creating collection: $e');
      if (!mounted) return;
      if (showSnackBar) {
        _showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        rethrow; // Dialog içinde handle etmek için
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Listelerim'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Beğendiklerim', icon: Icon(Icons.favorite)),
            Tab(text: 'Listelerim', icon: Icon(Icons.collections)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildCollectionsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 
          ? FloatingActionButton.extended(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Liste'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildFavoritesTab() {
    final filtered = _getFilteredFavoriteProducts();

    if (widget.favoriteProducts.isEmpty) {
      return ProfessionalComponents.createEmptyState(
        title: 'Henüz Favori Ürün Yok',
        message: 'Beğendiğiniz ürünleri favorilere ekleyin.',
        icon: Icons.favorite_border,
        buttonText: 'Ürünlere Göz At',
        onButtonPressed: widget.onNavigateToMainPage,
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    const double bottomNavHeight = kBottomNavigationBarHeight; // genelde ~56
    
    return SafeArea(
      top: false,
      bottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          // Üst kontrol çubuğu (arama + sayaç + sıralama/filtre)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    // Arama kutusu
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _favSearchQuery = v.trim()),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Beğendiklerimde ara...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _favSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _favSearchQuery = ''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Küçük sayaç etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length} ürün',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Sıralama
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _favSortBy,
                          items: const [
                            DropdownMenuItem(value: 'name_asc', child: Text('Ada göre')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Fiyat ↑')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Fiyat ↓')),
                          ],
                          onChanged: (v) => setState(() => _favSortBy = v ?? 'name_asc'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtre butonu
                    Container(
                      decoration: BoxDecoration(
                        color: _favFilterCategory != 'all' || _favMinPrice > 0 || _favMaxPrice < 10000 
                            ? Colors.blue[100] 
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _showFilterDialog,
                        icon: Icon(
                          Icons.filter_list,
                          color: _favFilterCategory != 'all' || _favMinPrice > 0 || _favMaxPrice < 10000 
                              ? Colors.blue[700] 
                              : Colors.grey[700],
                        ),
                        splashRadius: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Liste (Grid)
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 12 + bottomPadding + keyboardPadding + bottomNavHeight,
              ),
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _buildFavGridCard(product);
              },
            ),
          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Product> _getFilteredFavoriteProducts() {
    List<Product> list = List<Product>.from(widget.favoriteProducts);
    
    // Arama filtresi
    if (_favSearchQuery.isNotEmpty) {
      final q = _favSearchQuery.toLowerCase();
      list = list.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.description.toLowerCase().contains(q)
      ).toList();
    }
    
    // Kategori filtresi
    if (_favFilterCategory != 'all') {
      list = list.where((p) => p.category == _favFilterCategory).toList();
    }
    
    // Fiyat filtresi
    list = list.where((p) => p.price >= _favMinPrice && p.price <= _favMaxPrice).toList();
    
    // Sıralama
    switch (_favSortBy) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  // Beğendiklerim için kompakt grid kartı - Ana sayfa ile aynı yapı
  Widget _buildFavGridCard(Product product) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts.any((p) => p.id == product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createScaleRoute(
              UrunDetaySayfasi(
                product: product,
                favoriteProducts: widget.favoriteProducts,
                onFavoriteToggle: widget.onFavoriteToggle,
                onAddToCart: widget.onAddToCart,
                onRemoveFromCart: widget.onRemoveFromCart,
                cartProducts: widget.cartProducts,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ürün resmi
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OptimizedImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Ürün bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Butonlar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favori butonu - Animasyonlu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Haptic feedback
                                  HapticFeedback.lightImpact();
                                  // Anlık görsel geri bildirim
                                  setState(() {});
                                  // Favori işlemi
                                  widget.onFavoriteToggle(product);
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(isFavorite),
                                    size: isSmallScreen ? 14 : 16,
                                    color: isFavorite ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                                label: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    isFavorite ? 'Favoride' : 'Favori',
                                    key: ValueKey(isFavorite),
                                    style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFavorite ? Colors.red[50] : Colors.grey[50],
                                  foregroundColor: isFavorite ? Colors.red : Colors.grey[700],
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Sepete ekle butonu - Animasyonlu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Haptic feedback
                                  HapticFeedback.lightImpact();
                                  // Anlık görsel geri bildirim
                                  setState(() {});
                                  // Sepet işlemi
                                  if (inCart) {
                                    widget.onRemoveFromCart(product);
                                  } else {
                                    widget.onAddToCart(product);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inCart ? Colors.green[50] : Colors.blue[50],
                                  foregroundColor: inCart ? Colors.green : Colors.blue[700],
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                        key: ValueKey(inCart),
                                        size: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 2 : 4),
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          inCart ? 'Sepette' : 'Sepete',
                                          key: ValueKey(inCart),
                                          style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
  Widget _buildCollectionsTab() {
    if (_isLoading) {
      return ProfessionalComponents.createLoadingIndicator(
        message: 'Listeler yükleniyor...',
      );
    }

    if (_collections.isEmpty) {
      return ProfessionalComponents.createEmptyState(
        title: 'Henüz Liste Yok',
        message: 'Ürünlerinizi organize etmek için liste oluşturun.',
        icon: Icons.collections_bookmark_outlined,
        buttonText: 'Liste Oluştur',
        onButtonPressed: _showCreateCollectionDialog,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _collections.map((collection) {
          return _buildListCard(collection);
        }).toList(),
      ),
    );
  }

  Widget _buildListCard(Collection collection) {
    final products = collection.productIds
        .map((id) => widget.favoriteProducts.firstWhere(
              (p) => p.id == id,
              orElse: () => Product(
                id: id,
                name: 'Ürün Bulunamadı',
                description: '',
                price: 0,
                imageUrl: '',
                category: '',
                stock: 0,
              ),
            ))
        .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editCollection(collection),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liste başlığı ve tarih
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(collection.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCollectionOptions(collection),
                      icon: const Icon(Icons.more_vert),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              
              // Ürün grid'i
              if (products.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildProductGrid(products),
                ),
                const SizedBox(height: 16),
              ],
              
              // Alt butonlar (bookmark, görüntüleme, paylaş)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.bookmark_border,
                      label: '0',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.visibility_outlined,
                      label: '0',
                      onPressed: () {},
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _shareCollection(collection),
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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

  void _showCollectionTapOptions(Collection collection) {
    // Artık kullanılmıyor - direkt düzenleme sayfasına gidiyor
    _editCollection(collection);
  }

  Future<void> _viewCollectionDetail(Collection collection) async {
    try {
      final products = await CollectionService().getCollectionProducts(collection.id);
      if (!mounted) return;
      Navigator.push(
        context,
        ProfessionalAnimations.createScaleRoute(
          _ListDetailPage(
            collection: collection,
            products: products,
            onOpenProduct: (p) {
              Navigator.push(
                context,
                ProfessionalAnimations.createScaleRoute(
                  UrunDetaySayfasi(
                    product: p,
                    favoriteProducts: widget.favoriteProducts,
                    onFavoriteToggle: widget.onFavoriteToggle,
                    onAddToCart: widget.onAddToCart,
                    onRemoveFromCart: widget.onRemoveFromCart,
                    cartProducts: widget.cartProducts,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        SnackBar(content: Text('Liste yüklenemedi: $e')),
      );
    }
  }

  Future<void> _pickAndUploadCover(Collection collection) async {
    try {
      // Firebase'in başlatıldığını kontrol et
      if (Firebase.apps.isEmpty) {
        if (!mounted) return;
        _showSnackBar(
          const SnackBar(
            content: Text('Firebase başlatılmamış. Lütfen uygulamayı yeniden başlatın.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final picker = ImagePicker();
      if (!mounted) return;
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null || !mounted) return;

      // Loading göster
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final picked = await picker.pickImage(
        source: source, 
        imageQuality: 85, 
        maxWidth: 1600,
        maxHeight: 1600,
      );
      
      // Loading'i kapat
      if (mounted) Navigator.pop(context);
      
      if (picked == null) return;

      final file = File(picked.path);

      // Dosya boyutunu kontrol et (5MB limit)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (!mounted) return;
        _showSnackBar(
          const SnackBar(
            content: Text('Dosya çok büyük. 5MB\'dan küçük bir dosya seçin.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Koleksiyonlar için özelleştirilmiş yol kullan
      final adminService = admin.AdminService();
      
      print('Debug: Fotoğraf yükleniyor: collections/${collection.id}');
      try {
        final url = await adminService.uploadToPath(file, 'collections/${collection.id}')
            .timeout(const Duration(seconds: 30));
        print('Debug: Fotoğraf başarıyla yüklendi: $url');
        
        final updated = Collection(
          id: collection.id,
          name: collection.name,
          description: collection.description,
          userId: collection.userId,
          productIds: collection.productIds,
          createdAt: collection.createdAt,
          updatedAt: DateTime.now(),
          coverImageUrl: url,
        );
        await CollectionService().updateCollection(updated);
        if (!mounted) return;
        setState(() {
          final idx = _collections.indexWhere((c) => c.id == collection.id);
          if (idx != -1) _collections[idx] = updated;
        });
        if (!mounted) return;
        _showSnackBar(
          const SnackBar(
            content: Text('Kapak fotoğrafı başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (uploadError) {
        print('Debug: Fotoğraf yükleme hatası: $uploadError');
        throw Exception('Fotoğraf yüklenemedi. İnternet bağlantınızı kontrol edin: $uploadError');
      }

    } catch (e) {
      // Loading'i kapat
      if (mounted) Navigator.pop(context);
      
      if (!mounted) return;
      print('Debug: Fotoğraf yükleme hatası: $e');
      print('Debug: Hata tipi: ${e.runtimeType}');
      print('Debug: Stack trace: ${StackTrace.current}');
      _showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yüklenemedi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length > 4 ? 4 : products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        if (index == 3 && products.length > 4) {
          // "+X" göster
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+${products.length - 3}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: OptimizedImage(
            imageUrl: product.imageUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }


  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showCollectionOptions(Collection collection) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Ürün Ekle'),
              onTap: () {
                Navigator.pop(context);
                _showAddProductDialog(collection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _showEditCollectionDialog(collection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Sil'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCollectionDialog(collection);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareCollection(Collection collection) {
    // Paylaşım işlevi
    _showSnackBar(
      SnackBar(content: Text('${collection.name} listesi paylaşıldı')),
    );
  }

  void _showDeleteCollectionDialog(Collection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Sil'),
        content: Text('${collection.name} listesini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await CollectionService().deleteCollection(collection.id);
                if (mounted) {
                  setState(() {
                    _collections.removeWhere((c) => c.id == collection.id);
                  });
                  _showSnackBar(
                    SnackBar(content: Text('${collection.name} listesi silindi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showEditCollectionDialog(Collection collection) {
    _showCreateCollectionDialog(existingCollection: collection);
  }


  Widget _buildProductCard(Product product) {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.all(6), // Daha küçük margin
      child: Row(
        children: [
          // Ürün resmi
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: OptimizedImage(
              imageUrl: product.imageUrl,
              width: 60, // Daha küçük resim
              height: 60, // Daha küçük resim
            ),
          ),
          
          const SizedBox(width: 8), // Daha küçük spacing
          
          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14, // Daha küçük font
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 2), // Daha küçük spacing
                
                Text(
                  '${product.price.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontSize: 12, // Daha küçük font
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 4), // Daha küçük spacing
                
                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: ProfessionalComponents.createButton(
                        text: 'Detay',
                        onPressed: () {
                          Navigator.push(
                            context,
                            ProfessionalAnimations.createScaleRoute(
                              UrunDetaySayfasi(
                                product: product,
                                onFavoriteToggle: widget.onFavoriteToggle,
                                onAddToCart: widget.onAddToCart,
                                onRemoveFromCart: widget.onRemoveFromCart,
                                favoriteProducts: widget.favoriteProducts,
                                cartProducts: widget.cartProducts,
                              ),
                            ),
                          );
                        },
                        type: ButtonType.outline,
                        size: ButtonSize.small,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Expanded(
                      child: ProfessionalComponents.createButton(
                        text: 'Sepete Ekle',
                        onPressed: () => widget.onAddToCart(product),
                        type: ButtonType.primary,
                        size: ButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Favoriden çıkar butonu
          IconButton(
            onPressed: () => widget.onFavoriteToggle(product),
            icon: const Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(Collection collection) {
    return Card(
      margin: const EdgeInsets.all(6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewCollection(collection),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2), // Çok daha küçük padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Koleksiyon başlığı ve ikon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2), // Çok daha küçük padding
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3), // Daha küçük border radius
                    ),
                    child: Icon(
                      Icons.collections_bookmark,
                      color: Theme.of(context).primaryColor,
                      size: 10, // Daha küçük icon
                    ),
                  ),
                  const SizedBox(width: 4), // Çok daha küçük spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          collection.name,
                          style: const TextStyle(
                            fontSize: 12, // Daha küçük font
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1), // Daha küçük spacing
                        Text(
                          collection.description,
                          style: const TextStyle(
                            fontSize: 8, // Daha küçük font
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 6),
                            Text('Görüntüle', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 6),
                            Text('Düzenle', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_product',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 6),
                            Text('Ürün Ekle', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 6),
                            Text('Sil', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewCollection(collection);
                          break;
                        case 'edit':
                          _editCollection(collection);
                          break;
                        case 'add_product':
                          _showAddProductDialog(collection);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(collection);
                          break;
                      }
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 2), // Çok daha küçük spacing
              
              // Ürün sayısı ve tarih bilgileri
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Daha küçük padding
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6), // Daha küçük border radius
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2, size: 10, color: Colors.blue), // Daha küçük icon
                        const SizedBox(width: 1), // Daha küçük spacing
                        Text(
                          '${collection.productIds.length} ürün',
                          style: const TextStyle(
                            fontSize: 8, // Daha küçük font
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Daha küçük padding
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6), // Daha küçük border radius
                    ),
                    child: Text(
                      '${collection.createdAt.day}/${collection.createdAt.month}',
                      style: const TextStyle(
                        fontSize: 8, // Daha küçük font
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 2), // Çok daha küçük spacing
              
              // Alt butonlar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ProfessionalComponents.createButton(
                      text: 'Görüntüle',
                      onPressed: () => _viewCollection(collection),
                      type: ButtonType.outline,
                      size: ButtonSize.small,
                    ),
                  ),
                  const SizedBox(width: 4), // Çok daha küçük spacing
                  Expanded(
                    child: ProfessionalComponents.createButton(
                      text: 'Ürün Ekle',
                      onPressed: () => _showAddProductDialog(collection),
                      type: ButtonType.primary,
                      size: ButtonSize.small,
                    ),
                  ),
                  const SizedBox(width: 4), // Çok daha küçük spacing
                  Expanded(
                    child: ProfessionalComponents.createButton(
                      text: 'Düzenle',
                      onPressed: () => _editCollection(collection),
                      type: ButtonType.outline,
                      size: ButtonSize.small,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewCollection(Collection collection) {
    // Navigate to collection detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(collection.name),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections_bookmark,
                  size: 80,
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 20),
                Text(
                  collection.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  collection.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${collection.productIds.length} ürün',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Koleksiyon detayları yakında eklenecek!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editCollection(Collection collection) {
    _showCreateCollectionDialog(existingCollection: collection);
  }

  void _showDeleteConfirmation(Collection collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Koleksiyonu Sil'),
          content: Text('${collection.name} koleksiyonunu silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCollection(collection);
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCollection(Collection collection) async {
    try {
      await CollectionService().deleteCollection(collection.id);
      if (!mounted) return;
      _loadCollections();
      
      if (!mounted) return;
      _showSnackBar(
        const SnackBar(
          content: Text('Koleksiyon silindi!'),
          backgroundColor: Colors.red,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtre Seçenekleri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kategori filtresi
                const Text('Kategori:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _favFilterCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Tüm Kategoriler')),
                    ...widget.favoriteProducts
                        .map((p) => p.category)
                        .toSet()
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _favFilterCategory = value ?? 'all';
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Fiyat aralığı
                const Text('Fiyat Aralığı:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _favMinPrice.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Min Fiyat',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setDialogState(() {
                            _favMinPrice = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _favMaxPrice.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Max Fiyat',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setDialogState(() {
                            _favMaxPrice = double.tryParse(value) ?? 10000;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _favFilterCategory = 'all';
                  _favMinPrice = 0;
                  _favMaxPrice = 10000;
                });
              },
              child: const Text('Sıfırla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(Collection collection) {
    final productService = ProductService();
    
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        collection: collection,
        productService: productService,
        onProductAdded: () => _loadCollections(),
        favoriteProducts: widget.favoriteProducts,
        cartProducts: widget.cartProducts,
        onFavoriteToggle: widget.onFavoriteToggle,
        onAddToCart: widget.onAddToCart,
        onRemoveFromCart: widget.onRemoveFromCart,
      ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  final Collection collection;
  final ProductService productService;
  final VoidCallback onProductAdded;
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;

  const _AddProductDialog({
    required this.collection,
    required this.productService,
    required this.onProductAdded,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  String searchQuery = '';
  bool isLoading = true;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await widget.productService.getAllProducts();
      if (mounted) {
        setState(() {
          allProducts = products;
          filteredProducts = products;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text('${widget.collection.name} - Ürün Ekle'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arama kutusu
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                  if (searchQuery.isEmpty) {
                    filteredProducts = allProducts;
                  } else {
                    filteredProducts = allProducts.where((product) {
                      return product.name.toLowerCase().contains(searchQuery) ||
                             product.description.toLowerCase().contains(searchQuery) ||
                             product.category.toLowerCase().contains(searchQuery);
                    }).toList();
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            // Ürün listesi
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'Aradığınız ürün bulunamadı'
                                    : 'Ürün bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final isAlreadyAdded = widget.collection.productIds.contains(product.id);
                            
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: OptimizedImage(
                                  imageUrl: product.imageUrl,
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                              title: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${product.price.toStringAsFixed(2)} ₺',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isAlreadyAdded
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 24,
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: Theme.of(context).primaryColor,
                                      onPressed: () async {
                                        try {
                                          await CollectionService()
                                              .addProductToCollection(
                                            widget.collection.id,
                                            product.id,
                                            productImageUrl: product.imageUrl,
                                          );
                                          if (!mounted) return;
                                          setState(() {});
                                          if (!mounted) return;
                                          try {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${product.name} eklendi!'),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          } catch (_) {
                                            // Context deaktif, sessizce devam et
                                          }
                                          widget.onProductAdded();
                                        } catch (e) {
                                          if (!mounted) return;
                                          try {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Hata: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          } catch (_) {
                                            // Context deaktif, sessizce devam et
                                          }
                                        }
                                      },
                                    ),
                              onTap: () {
                                // Ürün detay sayfasına git
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  ProfessionalAnimations.createScaleRoute(
                                    UrunDetaySayfasi(
                                      product: product,
                                      favoriteProducts: widget.favoriteProducts,
                                      cartProducts: widget.cartProducts,
                                      onFavoriteToggle: widget.onFavoriteToggle,
                                      onAddToCart: widget.onAddToCart,
                                      onRemoveFromCart: widget.onRemoveFromCart,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}

// Liste detay sayfası
// Basit bir grid içinde ürünleri gezilebilir şekilde gösterir
// Ürün tıklandığında dışarıdan verilen onOpenProduct çağrılır
// Kapak görseli varsa üstte gösterilir
// Bu sayfa sadece görüntüleme amaçlıdır
class _ListDetailPage extends StatelessWidget {
  final Collection collection;
  final List<Product> products;
  final void Function(Product) onOpenProduct;
  const _ListDetailPage({
    required this.collection,
    required this.products,
    required this.onOpenProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(collection.name)),
      body: Column(
        children: [
          if ((collection.coverImageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: OptimizedImage(
                imageUrl: collection.coverImageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOpenProduct(product),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: OptimizedImage(
                                imageUrl: product.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price.toStringAsFixed(2)} ₺',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
