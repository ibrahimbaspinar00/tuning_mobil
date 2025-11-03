import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_data_service.dart';
import '../services/order_service.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import '../providers/app_state_provider.dart';
import '../utils/professional_error_handler.dart';
import 'siparisler_sayfasi.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';
import 'bildirim_ayarlari_sayfasi.dart';
import 'para_yukleme_sayfasi.dart';
import 'giris_sayfasi.dart';
import 'main_screen.dart';
import 'profil_duzenleme_sayfasi.dart';

class HesabimSayfasi extends StatefulWidget {
  const HesabimSayfasi({super.key});

  @override
  State<HesabimSayfasi> createState() => _HesabimSayfasiState();
}

class _HesabimSayfasiState extends State<HesabimSayfasi> {
  String _userName = 'Kullanıcı';
  String _userEmail = 'kullanici@example.com';
  double _walletBalance = 0.0;
  int _orderCount = 0;
  int _favoriteCount = 0;
  // Siparişler özet kartı kaldırıldığı için bu state'ler kullanılmıyor
  
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  final OrderService _orderService = OrderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _favoritesSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _attachRealtimeListeners();
  }

  Future<void> _loadUserData() async {
    try {
      // Kullanıcı giriş yapmış mı kontrol et
      final user = _auth.currentUser;
      if (user == null) {
        // Kullanıcı giriş yapmamış - varsayılan değerlerle devam et
        if (mounted) {
          setState(() {
            _userName = 'Misafir Kullanıcı';
            _userEmail = 'Giriş yapmak için tıklayın';
            // Oturum yoksa, favori sayısını uygulama state'inden al (kalıcılık için fallback)
            _favoriteCount = context.read<AppStateProvider>().favoriteProducts.length;
            _orderCount = 0;
          });
        }
        return;
      }
      
      // Firebase'den kullanıcı bilgilerini yükle
      final userProfile = await _firebaseDataService.getUserProfile();
      final userStats = await _firebaseDataService.getUserStats();
      
      if (mounted) {
        setState(() {
          _userName = userProfile?['fullName'] ?? 'Kullanıcı';
          _userEmail = userProfile?['email'] ?? 'kullanici@example.com';
          _walletBalance = userStats['walletBalance']?.toDouble() ?? 0.0;
          _orderCount = userStats['totalOrders'] ?? 0;
          _favoriteCount = userStats['favoriteCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _attachRealtimeListeners() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Realtime orders count
    _ordersSub?.cancel();
    _ordersSub = _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      int totalOrders = snapshot.docs.length;
      setState(() {
        _orderCount = totalOrders;
      });
    });

    // Realtime favorites count
    _favoritesSub?.cancel();
    _favoritesSub = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _favoriteCount = snapshot.docs.length;
      });
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _favoritesSub?.cancel();
    super.dispose();
  }

  

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ProfessionalErrorHandler.showError(
        context: context,
        title: 'Çıkış Hatası',
        message: 'Çıkış yapılırken hata oluştu: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      backgroundColor: Colors.grey[50],
      appBar: ProfessionalComponents.createAppBar(
        title: 'Hesabım',
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profil kartı
            _buildProfileCard(),
            
            const SizedBox(height: 16),
            
            // Cüzdan kartı
            _buildWalletCard(),
            
            const SizedBox(height: 16),
            
            // İstatistikler
            _buildStatsCard(),

            const SizedBox(height: 16),
            
            // Menü seçenekleri
            _buildMenuOptions(),
            
            const SizedBox(height: 16),
            
            // Çıkış butonu
            _buildLogoutButton(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profil resmi ve bilgiler
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProfessionalComponents.createStatusBadge(
                      text: 'Aktif Üye',
                      type: StatusType.success,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    ProfessionalAnimations.createSlideRoute(
                      const ProfilDuzenlemeSayfasi(),
                    ),
                  );
                  // Profil güncellendiyse verileri yeniden yükle
                  if (result == true) {
                    _loadUserData();
                  }
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Profili Düzenle',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Cüzdan Bakiyesi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_walletBalance.toStringAsFixed(2)} ₺',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProfessionalComponents.createButton(
                  text: 'Para Yükle',
                  onPressed: () {
                    Navigator.push(
                      context,
                      ProfessionalAnimations.createScaleRoute(
                        const ParaYuklemeSayfasi(),
                      ),
                    );
                  },
                  type: ButtonType.primary,
                  size: ButtonSize.small,
                  icon: Icons.add,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProfessionalComponents.createButton(
                  text: 'Geçmiş',
                  onPressed: () {
                    // Cüzdan geçmişi
                  },
                  type: ButtonType.outline,
                  size: ButtonSize.small,
                  icon: Icons.history,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstatistikler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Siparişler',
                  '$_orderCount',
                  Icons.shopping_bag,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Favoriler',
                  '$_favoriteCount',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Puan',
                  '4.8',
                  Icons.star,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    final menuItems = [
      _MenuItem(
        title: 'Siparişlerim',
        subtitle: 'Geçmiş siparişlerinizi görüntüleyin',
        icon: Icons.shopping_bag,
        color: Colors.blue,
        onTap: () async {
          // Her açılışta güncel siparişleri getir
          final orders = await _orderService.getUserOrders();
          if (!mounted) return;
          Navigator.push(
            context,
            ProfessionalAnimations.createSlideRoute(
              SiparislerSayfasi(
                orders: orders,
              ),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Adres Yönetimi',
        subtitle: 'Teslimat adreslerinizi yönetin',
        icon: Icons.location_on,
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createSlideRoute(
              const AdresYonetimiSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Ödeme Yöntemleri',
        subtitle: 'Kart ve ödeme bilgileriniz',
        icon: Icons.credit_card,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createSlideRoute(
              const OdemeYontemleriSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Bildirim Ayarları',
        subtitle: 'Bildirim tercihlerinizi ayarlayın',
        icon: Icons.notifications,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createSlideRoute(
              const BildirimAyarlariSayfasi(),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Yardım ve Destek',
        subtitle: 'Sık sorulan sorular ve destek',
        icon: Icons.help,
        color: Colors.teal,
        onTap: () {
          _showHelpDialog();
        },
      ),
      _MenuItem(
        title: 'Hakkında',
        subtitle: 'Uygulama bilgileri',
        icon: Icons.info,
        color: Colors.grey,
        onTap: () {
          _showAboutDialog();
        },
      ),
    ];

    return ProfessionalAnimations.createStaggeredList(
      children: menuItems.map((item) {
        return _buildMenuItem(item);
      }).toList(),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: item.onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    final user = _auth.currentUser;
    final isLoggedIn = user != null;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: ProfessionalComponents.createButton(
        text: isLoggedIn ? 'Çıkış Yap' : 'Giriş Yap',
        onPressed: isLoggedIn ? _showLogoutDialog : _navigateToLogin,
        type: isLoggedIn ? ButtonType.danger : ButtonType.primary,
        size: ButtonSize.large,
        icon: isLoggedIn ? Icons.logout : Icons.login,
        isFullWidth: true,
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      ProfessionalAnimations.createSlideRoute(
        const GirisSayfasi(),
      ),
    ).then((value) {
      // Giriş yapıldıktan sonra kullanıcı bilgilerini yeniden yükle
      if (mounted) {
        _loadUserData();
      }
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Karanlık Tema'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // Tema değiştirme
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Dil'),
              trailing: const Text('Türkçe'),
              onTap: () {
                // Dil seçimi
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Bildirimler'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Bildirim ayarı
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    ProfessionalErrorHandler.showInfo(
      context: context,
      title: 'Yardım ve Destek',
      message: 'Herhangi bir sorunuz için bizimle iletişime geçin:\n\n📧 Email: destek@tuningstore.com\n📞 Telefon: 0850 123 45 67\n💬 WhatsApp: +90 555 123 45 67',
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Tuning Store',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.shopping_cart, size: 48),
      children: [
        const Text('Premium e-ticaret deneyimi için tasarlandı.'),
        const SizedBox(height: 16),
        const Text('© 2024 Tuning Store. Tüm hakları saklıdır.'),
      ],
    );
  }

  void _showLogoutDialog() {
    ProfessionalErrorHandler.showWarning(
      context: context,
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
      actionText: 'Çıkış Yap',
      onAction: () {
        Navigator.pop(context);
        _signOut();
      },
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
