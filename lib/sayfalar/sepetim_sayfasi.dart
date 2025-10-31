import 'package:flutter/material.dart';
import '../widgets/no_overflow.dart';
import '../model/product.dart';
import '../services/firebase_data_service.dart';
import '../services/order_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import '../utils/professional_error_handler.dart';
import 'odeme_sayfasi.dart';

class SepetimSayfasi extends StatefulWidget {
  final List<Product> cartProducts;
  final Function(Product) onRemoveFromCart;
  final Function(Product, int) onUpdateQuantity;
  final Function() onPlaceOrder;
  final VoidCallback? onNavigateToMainPage;

  const SepetimSayfasi({
    super.key,
    required this.cartProducts,
    required this.onRemoveFromCart,
    required this.onUpdateQuantity,
    required this.onPlaceOrder,
    this.onNavigateToMainPage,
  });

  @override
  State<SepetimSayfasi> createState() => _SepetimSayfasiState();
}

class _SepetimSayfasiState extends State<SepetimSayfasi> {
  final TextEditingController _couponController = TextEditingController();
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  bool _isCouponApplied = false;
  double _shippingCost = 25.0; // Sabit kargo ücreti
  bool _isLoading = false;
  
  // Services
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  final OrderService _orderService = OrderService();

  double get _subtotal {
    return widget.cartProducts.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  double get _couponDiscountAmount {
    return _subtotal * _couponDiscount;
  }

  double get _finalShippingCost {
    return _isCouponApplied && _couponDiscount >= 0.1 ? 0.0 : _shippingCost;
  }

  double get _total {
    return _subtotal - _couponDiscountAmount + _finalShippingCost;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ProfessionalErrorHandler.showWarning(
        context: context,
        title: 'Kupon Kodu Gerekli',
        message: 'Lütfen geçerli bir kupon kodu girin.',
      );
      return;
    }

    // Demo kupon kodları
    switch (couponCode.toUpperCase()) {
      case 'WELCOME10':
        setState(() {
          _couponDiscount = 0.10; // %10 indirim
          _appliedCoupon = couponCode;
          _isCouponApplied = true;
        });
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: '%10 indirim kazandınız!',
        );
        break;
      case 'SAVE20':
        setState(() {
          _couponDiscount = 0.20; // %20 indirim
          _appliedCoupon = couponCode;
          _isCouponApplied = true;
        });
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: '%20 indirim kazandınız!',
        );
        break;
      case 'FREESHIP':
        setState(() {
          _couponDiscount = 0.0;
          _appliedCoupon = couponCode;
          _isCouponApplied = true;
        });
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Kupon Uygulandı!',
          message: 'Ücretsiz kargo kazandınız!',
        );
        break;
      default:
        ProfessionalErrorHandler.showError(
          context: context,
          title: 'Geçersiz Kupon',
          message: 'Bu kupon kodu geçerli değil.',
        );
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponDiscount = 0.0;
      _appliedCoupon = '';
      _isCouponApplied = false;
      _couponController.clear();
    });
  }

  void _updateProductQuantity(Product product, int newQuantity) {
    if (newQuantity <= 0) {
      widget.onRemoveFromCart(product);
    } else {
      widget.onUpdateQuantity(product, newQuantity);
    }
  }

  Future<void> _proceedToCheckout() async {
    if (widget.cartProducts.isEmpty) {
      ProfessionalErrorHandler.showWarning(
        context: context,
        title: 'Sepet Boş',
        message: 'Sepetinizde ürün bulunmuyor.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcı bilgilerini al
      final userProfile = await _firebaseDataService.getUserProfile();
      
      // Sipariş oluştur
      final orderId = await _orderService.createOrder(
        products: widget.cartProducts,
        totalAmount: _total,
        customerName: userProfile?['fullName'] ?? 'Müşteri',
        customerEmail: userProfile?['email'] ?? 'musteri@example.com',
        customerPhone: userProfile?['phone'] ?? '555-0123',
        shippingAddress: userProfile?['address'] ?? 'Adres bilgisi',
        paymentMethod: 'Kredi Kartı',
        notes: _appliedCoupon.isNotEmpty ? 'Kupon: $_appliedCoupon' : null,
      );

      // Sepeti temizle
      for (final product in widget.cartProducts) {
        await _firebaseDataService.removeFromCart(product.id);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Sipariş Oluşturuldu!',
          message: 'Siparişiniz başarıyla oluşturuldu. Sipariş No: $orderId',
        );

        // Ödeme sayfasına yönlendir
        Navigator.push(
          context,
          ProfessionalAnimations.createSlideRoute(
            OdemeSayfasi(
              cartProducts: widget.cartProducts,
              appliedCoupon: _appliedCoupon,
              couponDiscount: _couponDiscount,
              isCouponApplied: _isCouponApplied,
              orderId: orderId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ProfessionalErrorHandler.showError(
          context: context,
          title: 'Sipariş Hatası',
          message: 'Sipariş oluşturulurken hata oluştu: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Ana sayfaya geri dön
            _navigateToMainPage();
          },
        ),
        actions: [
          if (widget.cartProducts.isNotEmpty)
            TextButton(
              onPressed: () {
                _showClearCartDialog();
              },
              child: const Text(
                'Temizle',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: widget.cartProducts.isEmpty
          ? NoOverflow(
              child: _buildEmptyCart(),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      // Ürün listesi - Scrollable olmalı
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildProductList(),
                        ),
                      ),
                      // Özet ve ödeme - Sabit kalmalı
                      _buildOrderSummary(),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return ProfessionalComponents.createEmptyState(
      title: 'Sepetiniz Boş',
      message: 'Alışverişe başlamak için ürün ekleyin.',
      icon: Icons.shopping_cart_outlined,
      buttonText: 'Alışverişe Başla',
      onButtonPressed: () {
        // Ana sayfaya yönlendirme - Bottom navigation'ı ana sayfaya (index 0) ayarla
        _navigateToMainPage();
      },
    );
  }

  void _navigateToMainPage() {
    // Ana sayfaya yönlendirme için bottom navigation'ı kullan
    // MainScreen'deki _onItemTapped(0) metodunu çağır
    if (widget.onNavigateToMainPage != null) {
      widget.onNavigateToMainPage!();
    } else {
      // Fallback: Ana sayfaya geri dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildProductList() {
    return ProfessionalAnimations.createStaggeredList(
      children: widget.cartProducts.map((product) {
        return _buildProductCard(product);
      }).toList(),
    );
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
                
                // Miktar kontrolü
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _updateProductQuantity(product, product.quantity - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateProductQuantity(product, product.quantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Toplam fiyat ve sil butonu
          Column(
            children: [
              Text(
                '${(product.price * product.quantity).toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => widget.onRemoveFromCart(product),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kupon kodu
          _buildCouponSection(),
          
          const SizedBox(height: 16),
          
          // Sipariş özeti
          _buildOrderDetails(),
          
          const SizedBox(height: 16),
          
          // Ödemeye geç butonu
          SizedBox(
            width: double.infinity,
            child: ProfessionalComponents.createButton(
              text: 'Ödemeye Geç (${_total.toStringAsFixed(2)} ₺)',
              onPressed: _proceedToCheckout,
              type: ButtonType.primary,
              size: ButtonSize.large,
              icon: Icons.payment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kupon Kodu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(
                    hintText: 'Kupon kodunuzu girin',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!_isCouponApplied)
                ProfessionalComponents.createButton(
                  text: 'Uygula',
                  onPressed: _applyCoupon,
                  type: ButtonType.outline,
                  size: ButtonSize.small,
                )
              else
                ProfessionalComponents.createButton(
                  text: 'Kaldır',
                  onPressed: _removeCoupon,
                  type: ButtonType.danger,
                  size: ButtonSize.small,
                ),
            ],
          ),
          if (_isCouponApplied) ...[
            const SizedBox(height: 8),
            ProfessionalComponents.createStatusBadge(
              text: 'Kupon: $_appliedCoupon',
              type: StatusType.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      children: [
        _buildOrderRow('Ara Toplam', _subtotal.toStringAsFixed(2)),
        if (_couponDiscountAmount > 0)
          _buildOrderRow('İndirim', '-${_couponDiscountAmount.toStringAsFixed(2)}', isDiscount: true),
        _buildOrderRow('Kargo', _finalShippingCost.toStringAsFixed(2)),
        const Divider(),
        _buildOrderRow('Toplam', _total.toStringAsFixed(2), isTotal: true),
      ],
    );
  }

  Widget _buildOrderRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
          Text(
            '$value ₺',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isDiscount ? Colors.green : isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    ProfessionalErrorHandler.showWarning(
      context: context,
      title: 'Sepeti Temizle',
      message: 'Sepetinizdeki tüm ürünler silinecek. Emin misiniz?',
      actionText: 'Temizle',
      onAction: () {
        for (final product in widget.cartProducts) {
          widget.onRemoveFromCart(product);
        }
        Navigator.pop(context);
      },
    );
  }
}
