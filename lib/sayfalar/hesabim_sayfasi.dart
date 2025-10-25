import 'package:flutter/material.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import '../utils/professional_error_handler.dart';
import 'profil_bilgileri_sayfasi.dart';
import 'siparisler_sayfasi.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';
import 'bildirim_ayarlari_sayfasi.dart';
import 'para_yukleme_sayfasi.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Demo veriler
    setState(() {
      _userName = 'Ahmet Yılmaz';
      _userEmail = 'ahmet@example.com';
      _walletBalance = 250.50;
      _orderCount = 5;
      _favoriteCount = 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: SingleChildScrollView(
        child: Column(
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
    );
  }

  Widget _buildProfileCard() {
    return ProfessionalComponents.createCard(
      margin: const EdgeInsets.all(16),
      child: Column(
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
                onPressed: () {
                  Navigator.push(
                    context,
                    ProfessionalAnimations.createSlideRoute(
                      const ProfilBilgileriSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
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
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createSlideRoute(
              const SiparislerSayfasi(),
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
    return Container(
      margin: const EdgeInsets.all(16),
      child: ProfessionalComponents.createButton(
        text: 'Çıkış Yap',
        onPressed: _showLogoutDialog,
        type: ButtonType.danger,
        size: ButtonSize.large,
        icon: Icons.logout,
        isFullWidth: true,
      ),
    );
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
        // Çıkış işlemi
        Navigator.pop(context);
        ProfessionalErrorHandler.showSuccess(
          context: context,
          title: 'Çıkış Yapıldı',
          message: 'Başarıyla çıkış yaptınız.',
        );
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
