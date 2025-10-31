import 'package:flutter/material.dart';
import '../widgets/no_overflow.dart';
import '../model/product.dart';
import '../services/admin_service.dart';
import '../services/user_auth_service.dart';
import '../services/discount_wheel_service.dart';
import '../widgets/error_handler.dart';
import 'kayit_sayfasi.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';

class OdemeSayfasi extends StatefulWidget {
  final List<Product> cartProducts;
  final String appliedCoupon;
  final double couponDiscount;
  final bool isCouponApplied;
  final String? orderId;

  const OdemeSayfasi({
    super.key,
    required this.cartProducts,
    this.appliedCoupon = '',
    this.couponDiscount = 0.0,
    this.isCouponApplied = false,
    this.orderId,
  });

  @override
  State<OdemeSayfasi> createState() => _OdemeSayfasiState();
}

class _OdemeSayfasiState extends State<OdemeSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String _selectedPaymentMethod = 'credit_card';
  String _selectedDeliveryMethod = 'standard';
  bool _isLoading = false;
  bool _showCardForm = false;
  bool _showBankTransfer = false;
  bool _isGuestUser = true; // Misafir kullanıcı kontrolü
  
  // Kupon sistemi
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  bool _isCouponApplied = false;
  
  // Çark ödülleri
  final DiscountWheelService _wheelService = DiscountWheelService();
  List<ActiveReward> _activeRewards = [];
  // Seçilen kayıtlı adres ve kart
  Adres? _selectedSavedAddress;
  OdemeYontemi? _selectedSavedCard;
  
  // Kredi kartı bilgileri
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _couponController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _nameController.text = '';
    _emailController.text = '';
    _phoneController.text = '';
    _addressController.text = '';
    _postalCodeController.text = '';
    _checkUserLoginStatus();
    _loadUserData();
    _loadSavedAddresses();
    _loadSavedPaymentMethods();
    _loadActiveRewards();
    
    // Sepet sayfasından gelen kupon bilgilerini ayarla
    _appliedCoupon = widget.appliedCoupon;
    _couponDiscount = widget.couponDiscount;
    _isCouponApplied = widget.isCouponApplied;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Kullanıcı giriş durumunu kontrol et
  void _checkUserLoginStatus() {
    final userAuthService = UserAuthService();
    setState(() {
      _isGuestUser = userAuthService.getCurrentUser() == null;
    });
  }

  // Kayıtlı adresleri yükle
  Future<void> _loadSavedAddresses() async {
    if (!_isGuestUser) {
      try {
        // TODO: Implement getUserAddresses method in AdminService
        // final addresses = await AdminService().getUserAddresses();
        // if (addresses.isNotEmpty) {
        //   setState(() {
        //     _selectedSavedAddress = addresses.first;
        //     _fillAddressFromSaved(_selectedSavedAddress!);
        //   });
        // }
      } catch (e) {
        debugPrint('Adresler yüklenirken hata: $e');
      }
    }
  }

  // Kullanıcı bilgilerini otomatik doldur
  Future<void> _loadUserData() async {
    if (!_isGuestUser) {
      try {
        final userAuthService = UserAuthService();
        final user = userAuthService.getCurrentUser();
        if (user != null) {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            // Telefon numarası için profil bilgilerinden alınabilir
            _phoneController.text = '';
          });
        }
      } catch (e) {
        debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');
      }
    }
  }
  
  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kupon kodunu girin')),
      );
      return;
    }
    
    // Önce çark kupon kodlarını kontrol et
    final wheelReward = _wheelService.useCouponCode(couponCode);
    if (wheelReward != null) {
      setState(() {
        _appliedCoupon = wheelReward.couponCode ?? '';
        _couponDiscount = wheelReward.discountPercent / 100;
        _isCouponApplied = true;
        _activeRewards = _wheelService.getActiveRewards();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${wheelReward.name} kuponu uygulandı!'),
          backgroundColor: wheelReward.color,
        ),
      );
      return;
    }
    
    // Manuel kupon kodlarını kontrol et
    switch (couponCode.toUpperCase()) {
      case 'DISCOUNT5':
        setState(() {
          _appliedCoupon = 'DISCOUNT5';
          _couponDiscount = 0.05; // %5 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %5 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT10':
        setState(() {
          _appliedCoupon = 'DISCOUNT10';
          _couponDiscount = 0.10; // %10 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %10 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT15':
        setState(() {
          _appliedCoupon = 'DISCOUNT15';
          _couponDiscount = 0.15; // %15 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %15 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT20':
        setState(() {
          _appliedCoupon = 'DISCOUNT20';
          _couponDiscount = 0.20; // %20 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %20 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT25':
        setState(() {
          _appliedCoupon = 'DISCOUNT25';
          _couponDiscount = 0.25; // %25 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %25 İndirim kuponu uygulandı!')),
        );
        break;
      case 'FREESHIP':
        setState(() {
          _appliedCoupon = 'FREESHIP';
          _couponDiscount = 0.0; // Ücretsiz kargo
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Ücretsiz kargo kuponu uygulandı!')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Geçersiz kupon kodu')),
        );
    }
  }
  
  void _removeCoupon() {
    setState(() {
      _appliedCoupon = '';
      _couponDiscount = 0.0;
      _isCouponApplied = false;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kupon kaldırıldı')),
    );
  }
  
  Future<void> _loadActiveRewards() async {
    try {
      await _wheelService.initialize();
      setState(() {
        _activeRewards = _wheelService.getActiveRewards();
      });
    } catch (e) {
      // Çark ödülleri yüklenemedi
    }
  }
  
  void _useReward(ActiveReward reward) {
    if (reward.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ödülün süresi dolmuş')),
      );
      return;
    }
    
    if (reward.isUsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ödül zaten kullanılmış')),
      );
      return;
    }
    
    // Ödülü kullan
    final success = _wheelService.useReward(reward.id);
    if (success) {
      setState(() {
        _couponDiscount = reward.discountPercent / 100;
        _appliedCoupon = reward.id;
        _isCouponApplied = true;
        _activeRewards = _wheelService.getActiveRewards();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${reward.name} ödülü kullanıldı!'),
          backgroundColor: reward.color,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödül kullanılırken hata oluştu')),
      );
    }
  }

  // Kayıtlı ödeme yöntemlerini yükle
  Future<void> _loadSavedPaymentMethods() async {
    if (!_isGuestUser) {
      try {
        // TODO: Implement getUserPaymentMethods method in AdminService
        // final paymentMethods = await AdminService().getUserPaymentMethods();
        // if (paymentMethods.isNotEmpty) {
        //   setState(() {
        //     _selectedSavedCard = paymentMethods.first;
        //   });
        // }
      } catch (e) {
        debugPrint('Ödeme yöntemleri yüklenirken hata: $e');
      }
    }
  }


  double get _subtotal => widget.cartProducts.fold(0.0, (sum, product) => sum + product.totalPrice);
  double get _shippingCost => _selectedDeliveryMethod == 'express' ? 25.0 : 15.0;
  double get _couponDiscountAmount => _subtotal * _couponDiscount;
  double get _finalShippingCost => _appliedCoupon == 'FREESHIP' ? 0.0 : _shippingCost;
  double get _total => _subtotal - _couponDiscountAmount + _finalShippingCost;


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ödeme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : NoOverflow(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // Kullanıcı Durumu Bilgisi
                    _buildUserStatusInfo(),
                    const SizedBox(height: 16),
                    
                  // Sipariş Özeti
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  
                  // Teslimat Bilgileri
                  _buildDeliveryInfo(),
                    const SizedBox(height: 16),
                    if (!_isGuestUser) _buildSavedAddressPicker(),
                  const SizedBox(height: 24),
                  
                  // Ödeme Yöntemi
                  _buildPaymentMethod(),
                    if (_selectedPaymentMethod == 'credit_card' && !_isGuestUser)
                      _buildSavedCardPicker(),
                  const SizedBox(height: 24),
                  
                  // Kredi Kartı Formu
                  if (_showCardForm) ...[
                    _buildCreditCardForm(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Banka Havalesi Bilgileri
                  if (_showBankTransfer) ...[
                    _buildBankTransferInfo(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Teslimat Seçenekleri
                  _buildDeliveryOptions(),
                  const SizedBox(height: 24),
                  
                  // Ödeme Butonu
                  _buildPaymentButton(),
                  const SizedBox(height: 16), // Extra space at bottom
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Kullanıcı durumu bilgisi
  Widget _buildUserStatusInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isGuestUser ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isGuestUser ? Colors.orange[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isGuestUser ? Icons.person_outline : Icons.person,
            color: _isGuestUser ? Colors.orange[600] : Colors.green[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGuestUser ? 'Misafir Kullanıcı' : 'Kullanıcı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isGuestUser ? Colors.orange[700] : Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                if (_isGuestUser)
                  Text(
                    'Gelişmiş özellikleri kullanmak ve sipariş vermek için kayıt olunuz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
              ],
            ),
          ),
          if (_isGuestUser)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KayitSayfasi()),
                ).then((_) => _checkUserLoginStatus());
              },
              child: const Text('Kayıt Ol'),
            ),
        ],
        ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sipariş Özeti',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
            ),
            ),
            const SizedBox(height: 16),
            ...widget.cartProducts.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                          product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${product.quantity}x',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                    '₺${product.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            
            // Kupon Alanı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Kupon Kodu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: InputDecoration(
                            hintText: 'Kupon kodunu girin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isCouponApplied ? _removeCoupon : _applyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCouponApplied ? Colors.red[600] : Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(_isCouponApplied ? 'Kaldır' : 'Aktif Et'),
                      ),
                    ],
                  ),
                  if (_isCouponApplied) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _appliedCoupon == 'FREESHIP' 
                                ? 'Ücretsiz kargo kuponu uygulandı!'
                                : '${(_couponDiscount.isFinite ? (_couponDiscount * 100).toInt() : 0)}% İndirim kuponu uygulandı!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Çark Ödülleri
                  if (_activeRewards.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Çark Ödülleriniz:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._activeRewards.map((reward) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: reward.color.withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: reward.color.withOpacity( 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(reward.icon, color: reward.color, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reward.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: reward.color,
                                  ),
                                ),
                                Text(
                                  'Kalan süre: ${reward.timeRemainingString}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _useReward(reward),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: reward.color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Kullan', 
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ara Toplam:', style: TextStyle(fontSize: 16)),
                Text('₺${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            if (_isCouponApplied && _couponDiscountAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('İndirim:', style: TextStyle(fontSize: 16, color: Colors.green[600])),
                  Text('-₺${_couponDiscountAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.green[600], fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kargo:', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text('₺${_finalShippingCost.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₺${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const Text(
                  'Teslimat Bilgileri',
                  style: TextStyle(
                fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
            const SizedBox(height: 16),
            
            // Kişisel Bilgiler Bölümü
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Ad soyad gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value?.isEmpty == true ? 'E-posta gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty == true ? 'Telefon gerekli' : null,
                  ),
                ],
              ),
            ),
            
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const Text(
                  'Ödeme Yöntemi',
                  style: TextStyle(
                fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
            const SizedBox(height: 16),
            
            // Kredi Kartı
            RadioListTile<String>(
              title: const Text('Kredi Kartı'),
              subtitle: Text(
                _isGuestUser
                    ? 'Kayıt olup kart kaydedin, sonra kullanın'
                    : 'Kayıtlı kartlarınızdan birini seçin',
              ),
              value: 'credit_card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                  // Artık inline kart formu yok; sadece kayıtlı kart seçimi
                  _showCardForm = false;
                  _showBankTransfer = false;
                });
              },
            ),
            
            // Kapıda Ödeme
            RadioListTile<String>(
              title: const Text('Kapıda Ödeme'),
              subtitle: const Text('Teslimat sırasında ödeme'),
              value: 'cash_on_delivery',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                  _showCardForm = false;
                  _showBankTransfer = false;
                });
              },
            ),
            
            // Banka Havalesi
            RadioListTile<String>(
              title: const Text('Banka Havalesi'),
              subtitle: const Text('Manuel onay gerekir'),
              value: 'bank_transfer',
        groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
          _selectedPaymentMethod = value!;
                  _showCardForm = false;
          _showBankTransfer = value == 'bank_transfer';
                });
              },
            ),
            
            // Misafir kullanıcılar için uyarı
            if (_isGuestUser && _selectedPaymentMethod == 'credit_card')
                Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
          children: [
                    Icon(Icons.info, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
            Expanded(
              child: Text(
                        'Kart kaydetmek ve kullanmak için kayıt olmanız gerekiyor.',
                style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                ),
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

  Widget _buildCreditCardForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kredi Kartı Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (!_isGuestUser)
                  TextButton.icon(
                    onPressed: _showSaveCardDialog,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Kart Kaydet'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
              ],
                  ),
                  const SizedBox(height: 16),
            
                  TextFormField(
              controller: _cardNameController,
                    decoration: InputDecoration(
                labelText: 'Kart Üzerindeki İsim',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
              validator: (value) => value?.isEmpty == true ? 'Kart üzerindeki isim gerekli' : null,
                  ),
            
                  const SizedBox(height: 16),
            
                  TextFormField(
              controller: _cardNumberController,
                    decoration: InputDecoration(
                labelText: 'Kart Numarası',
                hintText: '1234 5678 9012 3456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Kart numarası gerekli' : null,
                  ),
            
                  const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: 'Son Kullanma Tarihi',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Son kullanma tarihi gerekli' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'CVV gerekli' : null,
                            ),
                          ),
                        ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Banka Havalesi Bilgileri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
                  const Text(
              'Aşağıdaki hesap bilgilerine ödemenizi yapabilirsiniz:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Banka: Türkiye İş Bankası'),
                  const Text('Hesap Adı: Tuning Store'),
                  const Text('IBAN: TR12 0006 4000 0011 2345 6789 01'),
                  Text('Tutar: ₺${_total.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          Text(
              'Ödeme yaptıktan sonra dekontu WhatsApp hattımıza gönderebilirsiniz.',
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

  Widget _buildDeliveryOptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              'Teslimat Seçenekleri',
            style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
              const SizedBox(height: 16),
            
            RadioListTile<String>(
              title: const Text('Standart Teslimat'),
              subtitle: const Text('3-5 iş günü - ₺15'),
              value: 'standard',
              groupValue: _selectedDeliveryMethod,
                      onChanged: (value) {
                        setState(() {
                  _selectedDeliveryMethod = value!;
                        });
                      },
                    ),
            
            RadioListTile<String>(
              title: const Text('Hızlı Teslimat'),
              subtitle: const Text('1-2 iş günü - ₺25'),
              value: 'express',
              groupValue: _selectedDeliveryMethod,
                      onChanged: (value) {
                        setState(() {
                  _selectedDeliveryMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
      ),
    );
  }

  // Kayıtlı adres seçici
  Widget _buildSavedAddressPicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kayıtlı Adresler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSavedAddress == null
                        ? 'Seçili adres yok'
                        : '${_selectedSavedAddress!.title} - ${_selectedSavedAddress!.district}, ${_selectedSavedAddress!.city}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdresYonetimiSayfasi(selectMode: true),
                      ),
                    );
                    if (selected != null && mounted) {
                      setState(() {
                        _selectedSavedAddress = selected as Adres;
                        // Form alanlarını doldur
                        _nameController.text = _selectedSavedAddress!.fullName;
                        _phoneController.text = _selectedSavedAddress!.phone;
                        _addressController.text = _selectedSavedAddress!.address;
                        _postalCodeController.text = _selectedSavedAddress!.postalCode;
                      });
                    }
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Adres Seç'),
                ),
              ],
              ),
            ],
          ),
      ),
    );
  }

  // Kayıtlı kart seçici
  Widget _buildSavedCardPicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            const Text(
              'Kayıtlı Kartlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSavedCard == null
                        ? 'Seçili kart yok'
                        : '${_selectedSavedCard!.name} - ${_selectedSavedCard!.number}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OdemeYontemleriSayfasi(selectMode: true),
                      ),
                    );
                    if (selected != null && mounted) {
                        setState(() {
                        _selectedSavedCard = selected as OdemeYontemi;
                      });
                    }
                  },
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Kart Seç'),
                ),
              ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onPayPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Siparişi Tamamla',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
      ),
    );
  }

  // Ödeme butonu davranışı
  Future<void> _onPayPressed() async {
    if (_selectedPaymentMethod == 'credit_card') {
      if (_isGuestUser) {
        _showGuestUserDialog();
        return;
      }
      if (_selectedSavedCard == null) {
        ErrorHandler.showError(context, 'Lütfen kayıtlı bir kart seçin');
        return;
      }
    }

    if (_selectedSavedAddress == null) {
      // Adres seçimi zorunlu, misafir için de kendi girdikleri adres geçerli olacak
      if (_addressController.text.trim().isEmpty) {
        ErrorHandler.showError(context, 'Lütfen teslimat adresini doldurun veya seçin');
        return;
      }
    }

    await _processPayment();
  }

  void _showSaveCardDialog() {
    if (_isGuestUser) {
      _showGuestUserDialog();
      return;
    }

    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kart Kaydet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Kart Üzerindeki İsim',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Kart Numarası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                ),
              const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryController,
                        decoration: const InputDecoration(
                        labelText: 'Son Kullanma',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                  const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Kart bilgilerini kaydet
                if (nameController.text.isNotEmpty && 
                    numberController.text.isNotEmpty && 
                    expiryController.text.isNotEmpty && 
                    cvvController.text.isNotEmpty) {
                  
                  // Mevcut form alanlarını doldur
                  _cardNameController.text = nameController.text;
                  _cardNumberController.text = numberController.text;
                  _expiryController.text = expiryController.text;
                  _cvvController.text = cvvController.text;
                  
                  Navigator.of(context).pop();
                  ErrorHandler.showSuccess(context, 'Kart başarıyla kaydedildi!');
                } else {
                  ErrorHandler.showError(context, 'Lütfen tüm alanları doldurun');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
      ),
    );
  }

  void _showGuestUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt Gerekli'),
        content: const Text(
          'Gelişmiş özellikleri kullanmak ve sipariş vermek için kayıt olmanız gerekiyor. '
          'Kayıt olmak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KayitSayfasi()),
              ).then((_) => _checkUserLoginStatus());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Kayıt Ol'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminService = AdminService();
      
      // Müşteri bilgilerini hazırla
      final customerInfo = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'isGuest': _isGuestUser.toString(),
      };

      // Ürünleri Firebase formatına çevir
      final orderProducts = widget.cartProducts.map((product) => {
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'imageUrl': product.imageUrl,
      }).toList();

      final result = await adminService.createOrderWithStockCheck(orderProducts, customerInfo);

      if (result['success']) {
        // Başarılı sipariş
        if (mounted) {
          Navigator.of(context).pop();
          ErrorHandler.showSuccess(context, 'Siparişiniz başarıyla verildi!');
        }
      } else {
        if (mounted) {
          ErrorHandler.showError(context, result['error'] ?? 'Sipariş verilirken hata oluştu');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ödeme işlemi sırasında hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
