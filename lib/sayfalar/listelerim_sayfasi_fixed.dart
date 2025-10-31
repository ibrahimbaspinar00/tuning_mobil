import 'package:flutter/material.dart';
import '../model/product.dart';
import '../model/collection.dart';
import '../services/collection_service.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
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
  // State variables
  List<Collection> _collections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final collections = await CollectionService().getUserCollections();
      if (!mounted) return;
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading collections: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ... (diğer tüm metodlar buraya gelecek)
  // Burada sadece _showAddProductDialog metodunu gösteriyorum
  void _showAddProductDialog(Collection collection) {
    final productService = ProductService();
    
    showDialog(
      context: context,
      builder: (context) => _AddProductDialog(
        collection: collection,
        productService: productService,
        onProductAdded: () => _loadCollections(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listelerim'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? const Center(child: Text('Henüz liste oluşturmadınız'))
              : ListView.builder(
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collections[index];
                    return ListTile(
                      title: Text(collection.name),
                      subtitle: Text(collection.description),
                      onTap: () => _showAddProductDialog(collection),
                    );
                  },
                ),
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  final Collection collection;
  final ProductService productService;
  final VoidCallback onProductAdded;

  const _AddProductDialog({
    required this.collection,
    required this.productService,
    required this.onProductAdded,
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
                                          if (mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${product.name} eklendi!'),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                          widget.onProductAdded();
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Hata: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                              onTap: () {
                                // Ürün detay sayfasına git
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UrunDetaySayfasi(
                                      product: product,
                                      favoriteProducts: [],
                                      cartProducts: [],
                                      onFavoriteToggle: (_) {},
                                      onAddToCart: (_) {},
                                      onRemoveFromCart: (_) {},
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

