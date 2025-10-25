import 'package:flutter/material.dart';
import '../model/product.dart';
import '../model/collection.dart';
import '../services/collection_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import 'urun_detay_sayfasi.dart';

class ListelerimSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;

  const ListelerimSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  @override
  State<ListelerimSayfasi> createState() => _ListelerimSayfasiState();
}

class _ListelerimSayfasiState extends State<ListelerimSayfasi>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Collection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCollections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    
    try {
      final collections = await CollectionService().getUserCollections();
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Demo koleksiyonlar
      _loadDemoCollections();
    }
  }

  void _loadDemoCollections() {
    setState(() {
      _collections = [
        Collection(
          id: '1',
          name: 'Araç Temizlik Ürünleri',
          description: 'En iyi araç temizlik ürünleri',
          userId: 'demo_user',
          productIds: ['1', '2'],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Collection(
          id: '2',
          name: 'Telefon Aksesuarları',
          description: 'Telefon için gerekli aksesuarlar',
          userId: 'demo_user',
          productIds: ['3'],
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Collection(
          id: '3',
          name: 'Güvenlik Ürünleri',
          description: 'Araç güvenliği için ürünler',
          userId: 'demo_user',
          productIds: ['5'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    });
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Koleksiyon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Koleksiyon Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _createCollection(
                  nameController.text,
                  descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection(String name, String description) async {
    try {
      final collection = Collection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        userId: 'demo_user',
        productIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CollectionService().createCollection(collection);
      _loadCollections();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koleksiyon oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Listelerim'),
        actions: [
          IconButton(
            onPressed: _showCreateCollectionDialog,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Favoriler', icon: Icon(Icons.favorite)),
            Tab(text: 'Koleksiyonlar', icon: Icon(Icons.collections)),
            Tab(text: 'Geçmiş', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildCollectionsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (widget.favoriteProducts.isEmpty) {
      return ProfessionalComponents.createEmptyState(
        title: 'Henüz Favori Ürün Yok',
        message: 'Beğendiğiniz ürünleri favorilere ekleyin.',
        icon: Icons.favorite_border,
        buttonText: 'Ürünlere Göz At',
        onButtonPressed: () {
          // Ana sayfaya yönlendirme
        },
      );
    }

    return ProfessionalAnimations.createStaggeredList(
      children: widget.favoriteProducts.map((product) {
        return _buildProductCard(product);
      }).toList(),
    );
  }

  Widget _buildCollectionsTab() {
    if (_isLoading) {
      return ProfessionalComponents.createLoadingIndicator(
        message: 'Koleksiyonlar yükleniyor...',
      );
    }

    if (_collections.isEmpty) {
      return ProfessionalComponents.createEmptyState(
        title: 'Henüz Koleksiyon Yok',
        message: 'Ürünlerinizi organize etmek için koleksiyon oluşturun.',
        icon: Icons.collections_bookmark_outlined,
        buttonText: 'Koleksiyon Oluştur',
        onButtonPressed: _showCreateCollectionDialog,
      );
    }

    return ProfessionalAnimations.createStaggeredList(
      children: _collections.map((collection) {
        return _buildCollectionCard(collection);
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    return ProfessionalComponents.createEmptyState(
      title: 'Geçmiş Boş',
      message: 'Görüntülediğiniz ürünler burada görünecek.',
      icon: Icons.history,
    );
  }

  Widget _buildProductCard(Product product) {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Ürün resmi
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: OptimizedImage(
              imageUrl: product.imageUrl,
              width: 80,
              height: 80,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Ürün bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${product.price.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 8),
                
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
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Koleksiyon başlığı
          Row(
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
                      collection.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Düzenle'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Sil'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteCollection(collection);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Ürün sayısı
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${collection.productIds.length} ürün',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '${collection.createdAt.day}/${collection.createdAt.month}/${collection.createdAt.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Koleksiyonu görüntüle butonu
          SizedBox(
            width: double.infinity,
            child: ProfessionalComponents.createButton(
              text: 'Koleksiyonu Görüntüle',
              onPressed: () {
                // Koleksiyon detay sayfasına yönlendirme
              },
              type: ButtonType.primary,
              size: ButtonSize.small,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCollection(Collection collection) async {
    try {
      await CollectionService().deleteCollection(collection.id);
      _loadCollections();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koleksiyon silindi!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
