import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../model/collection.dart';
import '../model/product.dart';
import '../services/collection_service.dart';
import '../services/product_service.dart';
import '../widgets/error_handler.dart';
import '../config/app_routes.dart';

class KoleksiyonDetaySayfasi extends StatefulWidget {
  final Collection collection;

  const KoleksiyonDetaySayfasi({
    super.key,
    required this.collection,
  });

  @override
  State<KoleksiyonDetaySayfasi> createState() => _KoleksiyonDetaySayfasiState();
}

class _KoleksiyonDetaySayfasiState extends State<KoleksiyonDetaySayfasi> {
  final CollectionService _collectionService = CollectionService();
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCollectionProducts();
  }

  Future<void> _loadCollectionProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _collectionService.getCollectionProducts(widget.collection.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler yüklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> _deleteCollection() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koleksiyonu Sil'),
        content: Text('${widget.collection.name} koleksiyonunu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _collectionService.deleteCollection(widget.collection.id);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koleksiyon silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Koleksiyon silinirken hata oluştu: $e');
      }
    }
  }

  Future<void> _editCollection() async {
    final nameController = TextEditingController(text: widget.collection.name);
    final descriptionController = TextEditingController(text: widget.collection.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koleksiyonu Düzenle'),
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
              Navigator.pop(context, {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim(),
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedCollection = Collection(
          id: widget.collection.id,
          name: result['name'] ?? '',
          description: result['description'] ?? '',
          userId: widget.collection.userId,
          productIds: widget.collection.productIds,
          createdAt: widget.collection.createdAt,
          updatedAt: DateTime.now(),
          coverImageUrl: widget.collection.coverImageUrl,
        );

        await _collectionService.updateCollection(updatedCollection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Koleksiyon güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(context, 'Koleksiyon güncellenirken hata oluştu: $e');
        }
      }
    }
  }

  Future<void> _removeProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Çıkar'),
        content: Text('${product.name} ürününü koleksiyondan çıkarmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _collectionService.removeProductFromCollection(
        widget.collection.id,
        product.id,
      );
      await _loadCollectionProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} koleksiyondan çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürün çıkarılırken hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false, // Klavye performansı için
      appBar: AppBar(
        title: Text(
          widget.collection.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddProductsDialog,
            tooltip: 'Ürün Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCollection,
            tooltip: 'Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCollection,
            tooltip: 'Sil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? _buildEmptyState()
              : _buildProductsList(isSmallScreen),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bu koleksiyon boş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ürünleri bu koleksiyona eklemek için\nürün detay sayfasından ekleyebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddProductsDialog,
            icon: const Icon(Icons.add),
            label: const Text('Ürün Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _loadCollectionProducts,
      child: Column(
        children: [
          // Koleksiyon bilgileri
          Container(
            margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.collections, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.collection.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.collection.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.collection.description,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_products.length} ürün',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Güncelleme: ${_formatDate(widget.collection.updatedAt)}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddProductsDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ürün Ekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ürünler listesi
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product, isSmallScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateToProductDetail(
            context,
            product,
            favoriteProducts: const [],
            cartProducts: const [],
            onFavoriteToggle: (_) {},
            onAddToCart: (_) {},
            onRemoveFromCart: (_) {},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün görseli
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    Image.network(
                      product.imageUrl.isNotEmpty
                          ? product.imageUrl
                          : 'https://via.placeholder.com/300',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    ),
                    // Çıkar butonu
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _removeProduct(product),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Ürün bilgileri
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddProductsDialog() async {
    String searchQuery = '';
    List<Product> allProducts = [];
    List<Product> filteredProducts = [];
    bool isLoading = true;
    Set<String> selectedProductIds = {};
    final existingProductIds = widget.collection.productIds.toSet();

    // Ürünleri yükle
    try {
      allProducts = await _productService.getAllProducts();
      // Zaten koleksiyonda olan ürünleri filtrele
      filteredProducts = allProducts.where((p) => !existingProductIds.contains(p.id)).toList();
      isLoading = false;
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler yüklenirken hata oluştu: $e');
      }
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateFilter() {
            setDialogState(() {
              if (searchQuery.isEmpty) {
                filteredProducts = allProducts.where((p) => !existingProductIds.contains(p.id)).toList();
              } else {
                filteredProducts = allProducts.where((p) =>
                  !existingProductIds.contains(p.id) &&
                  (p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                   p.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
                   p.category.toLowerCase().contains(searchQuery.toLowerCase()))
                ).toList();
              }
            });
          }

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_shopping_cart, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ürün Ekle (${selectedProductIds.length} seçili)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Arama
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      child: TextField(
                        textInputAction: TextInputAction.search,
                        keyboardType: TextInputType.text,
                        enableSuggestions: false,
                        autocorrect: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        enableInteractiveSelection: true,
                        textCapitalization: TextCapitalization.none,
                        maxLines: 1,
                        style: const TextStyle(),
                        decoration: const InputDecoration(
                          hintText: 'Ürün ara...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                          updateFilter();
                        },
                      ),
                    ),
                  ),
                  // Ürün listesi
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      searchQuery.isEmpty
                                          ? 'Eklenebilecek ürün yok'
                                          : 'Arama sonucu bulunamadı',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final isSelected = selectedProductIds.contains(product.id);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          if (value == true) {
                                            selectedProductIds.add(product.id);
                                          } else {
                                            selectedProductIds.remove(product.id);
                                          }
                                        });
                                      },
                                      title: Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.price.toStringAsFixed(2)} ₺',
                                            style: TextStyle(
                                              color: Colors.blue[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      secondary: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrl.isNotEmpty
                                              ? product.imageUrl
                                              : 'https://via.placeholder.com/80',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: selectedProductIds.isEmpty
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    await _addProductsToCollection(selectedProductIds.toList());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Ekle (${selectedProductIds.length})'),
                          ),
                        ),
                      ],
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

  Future<void> _addProductsToCollection(List<String> productIds) async {
    if (productIds.isEmpty) return;

    try {
      int successCount = 0;
      int failCount = 0;

      for (final productId in productIds) {
        try {
          // Ürün bilgilerini al
          final product = await _productService.getProductById(productId);
          if (product != null) {
            await _collectionService.addProductToCollection(
              widget.collection.id,
              productId,
              productImageUrl: product.imageUrl,
            );
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
          debugPrint('Error adding product $productId: $e');
        }
      }

      await _loadCollectionProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? '$successCount ürün koleksiyona eklendi${failCount > 0 ? " ($failCount hata)" : ""}'
                  : 'Ürünler eklenirken hata oluştu',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ürünler eklenirken hata oluştu: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

