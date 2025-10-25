import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'web_admin_simple_products.dart';
import 'web_admin_stock_management.dart';
import 'web_admin_user_management.dart';
import 'web_admin_reports.dart';
import 'web_admin_settings.dart';
import 'web_admin_orders.dart';
import 'web_admin_price_management.dart';
import 'web_admin_notifications.dart';
import 'web_admin_main.dart';
import '../services/permission_service.dart';
import '../sayfalar/admin_review_management.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Demo veri ekleme kaldırıldı - artık otomatik demo ürün eklenmeyecek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive sidebar genişliği
          final sidebarWidth = constraints.maxWidth < 768 ? 0.0 : 
                              constraints.maxWidth < 1024 ? 240.0 : 280.0;
          final isMobile = constraints.maxWidth < 768;
          
          return Row(
        children: [
              // Sidebar - Mobile'da gizli
              if (!isMobile) ...[
          Container(
                  width: sidebarWidth,
            color: Colors.blue[900],
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 30,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Tuning App',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[200],
                        ),
                      ),
                      const SizedBox(height: 8),
                          // Giriş yapan kullanıcı adı - Anlık güncelleme
                          StreamBuilder<String>(
                            stream: Stream.periodic(const Duration(milliseconds: 500), (_) => PermissionService.getCurrentUserName() ?? 'Kullanıcı'),
                            builder: (context, snapshot) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  snapshot.data ?? 'Kullanıcı',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
                
                    // Navigation
                    Expanded(
                      child: ListView(
                        children: [
                            _buildNavItem(0, Icons.dashboard, 'Ana Sayfa'),
                          if (PermissionService.canViewProducts())
                            _buildNavItem(1, Icons.inventory, 'Ürün Yönetimi'),
                          if (PermissionService.canViewStock())
                            _buildNavItem(2, Icons.warehouse, 'Stok Yönetimi'),
                          if (PermissionService.canViewStock())
                            _buildNavItem(3, Icons.attach_money, 'Fiyat Yönetimi'),
                          if (PermissionService.canViewStock())
                            _buildNavItem(4, Icons.tune, 'Fiyat Ayarları'),
                          _buildNavItem(5, Icons.shopping_bag, 'Sipariş Yönetimi'),
                          if (PermissionService.canViewUsers())
                            _buildNavItem(6, Icons.people, 'Kullanıcı Yönetimi'),
                          if (PermissionService.canViewReports())
                            _buildNavItem(7, Icons.analytics, 'Raporlar'),
                          _buildNavItem(8, Icons.notifications, 'Bildirim Yönetimi'),
                          _buildNavItem(10, Icons.star, 'Yorum Yönetimi'),
                          if (PermissionService.canAccessSettings())
                            _buildNavItem(9, Icons.settings, 'Ayarlar'),
                        ],
                      ),
                    ),
                
                // Logout
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: const Text('Çıkış', style: TextStyle(color: Colors.white)),
                    onTap: () => _showLogoutDialog(),
                  ),
                ),
              ],
            ),
          ),
              ],
          
          // Main Content
          Expanded(
                child: Scaffold(
                  // Mobile AppBar
                  appBar: isMobile ? AppBar(
                    title: const Text('Admin Panel'),
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _showMobileDrawer(context),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => _showLogoutDialog(),
                      ),
                    ],
                  ) : null,
                  body: _getCurrentPage(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selected: _selectedIndex == index,
        selectedTileColor: Colors.blue[700],
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  // Çıkış yap dialogu
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Admin panelinden çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WebAdminApp()),
              );
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  // Mobile drawer göster
  void _showMobileDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Tuning App',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Navigation
            Expanded(
              child: ListView(
                children: [
                        _buildMobileNavItem(0, Icons.dashboard, 'Ana Sayfa'),
                  if (PermissionService.canViewProducts())
                    _buildMobileNavItem(1, Icons.inventory, 'Ürün Yönetimi'),
                  if (PermissionService.canViewStock())
                    _buildMobileNavItem(2, Icons.warehouse, 'Stok Yönetimi'),
                  if (PermissionService.canViewStock())
                    _buildMobileNavItem(3, Icons.attach_money, 'Fiyat Yönetimi'),
                  if (PermissionService.canViewStock())
                    _buildMobileNavItem(4, Icons.tune, 'Fiyat Ayarları'),
                  _buildMobileNavItem(5, Icons.shopping_bag, 'Sipariş Yönetimi'),
                  if (PermissionService.canViewUsers())
                    _buildMobileNavItem(6, Icons.people, 'Kullanıcı Yönetimi'),
                  if (PermissionService.canViewReports())
                    _buildMobileNavItem(7, Icons.analytics, 'Raporlar'),
                  if (PermissionService.canAccessSettings())
                    _buildMobileNavItem(8, Icons.settings, 'Ayarlar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selected: _selectedIndex == index,
        selectedTileColor: Colors.blue[100],
        leading: Icon(icon, color: _selectedIndex == index ? Colors.blue[800] : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: _selectedIndex == index ? Colors.blue[800] : Colors.black87,
            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context); // Drawer'ı kapat
        },
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const WebDashboardHome();
      case 1:
        return PermissionService.canViewProducts() 
            ? const WebAdminSimpleProducts() 
            : _buildAccessDeniedPage('Ürün Yönetimi');
      case 2:
        return PermissionService.canViewStock() 
            ? const WebAdminStockManagement() 
            : _buildAccessDeniedPage('Stok Yönetimi');
      case 3:
        return PermissionService.canViewStock() 
            ? const WebAdminPriceManagement() 
            : _buildAccessDeniedPage('Fiyat Yönetimi');
      case 4:
        return PermissionService.canViewStock() 
            ? const WebAdminStockManagement() 
            : _buildAccessDeniedPage('Stok Yönetimi');
      case 5:
        return const WebAdminOrders();
      case 6:
        return PermissionService.canViewUsers() 
            ? const WebAdminUserManagement() 
            : _buildAccessDeniedPage('Kullanıcı Yönetimi');
      case 7:
        return PermissionService.canViewReports() 
            ? const WebAdminReports() 
            : _buildAccessDeniedPage('Raporlar');
      case 8:
        return WebAdminNotifications();
      case 9:
        return PermissionService.canAccessSettings() 
            ? const WebAdminSettings() 
            : _buildAccessDeniedPage('Ayarlar');
      case 10:
        return const AdminReviewManagement();
      default:
        return const WebDashboardHome();
    }
  }

  Widget _buildAccessDeniedPage(String pageName) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
            size: 64,
            color: Colors.grey[400],
            ),
          const SizedBox(height: 16),
            Text(
              'Erişim Reddedildi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 8),
            Text(
              '$pageName sayfasına erişim yetkiniz bulunmamaktadır.',
              style: TextStyle(
                fontSize: 16,
              color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class WebDashboardHome extends StatelessWidget {
  const WebDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin mesajı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  const Text(
                    'Hoş Geldiniz!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                        Text(
                    'Admin paneline hoş geldiniz. Sisteminizi buradan yönetebilirsiniz.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                        ),
                      ],
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // İstatistikler
            const Text(
              'Sistem İstatistikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Dashboard istatistikleri
            FutureBuilder<Map<String, dynamic>>(
              future: _getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }
                
                final stats = snapshot.data ?? {};
                final totalProducts = stats['totalProducts'] ?? 0;
                final lowStockProducts = stats['lowStockProducts'] ?? 0;
                final activeProducts = stats['activeProducts'] ?? 0;
                final categories = stats['categories'] ?? 0;
                final totalOrders = stats['totalOrders'] ?? 0;
                final pendingOrders = stats['pendingOrders'] ?? 0;
                final completedOrders = stats['completedOrders'] ?? 0;
                final totalRevenue = stats['totalRevenue'] ?? 0.0;
                final totalUsers = stats['totalUsers'] ?? 0;
                final activeUsers = stats['activeUsers'] ?? 0;
                
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid hesaplama
                    int crossAxisCount;
                    double childAspectRatio;
                    
                    if (constraints.maxWidth > 1200) {
                      crossAxisCount = 4;
                      childAspectRatio = 2.2;
                    } else if (constraints.maxWidth > 800) {
                      crossAxisCount = 2;
                      childAspectRatio = 2.0;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.8;
                    }
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                  crossAxisSpacing: constraints.maxWidth < 768 ? 8 : constraints.maxWidth < 1024 ? 10 : 12,
                  mainAxisSpacing: constraints.maxWidth < 768 ? 8 : constraints.maxWidth < 1024 ? 10 : 12,
                      childAspectRatio: childAspectRatio,
                  children: [
                    _buildStatCard(
                      'Toplam Ürün',
                      totalProducts.toString(),
                      Icons.inventory,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Düşük Stok',
                      lowStockProducts.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Aktif Ürün',
                      activeProducts.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Kategori',
                      categories.toString(),
                      Icons.category,
                      Colors.purple,
                    ),
                        _buildStatCard(
                          'Toplam Sipariş',
                          totalOrders.toString(),
                          Icons.shopping_bag,
                          Colors.indigo,
                        ),
                        _buildStatCard(
                          'Bekleyen Sipariş',
                          pendingOrders.toString(),
                          Icons.pending,
                          Colors.amber,
                        ),
                        _buildStatCard(
                          'Tamamlanan',
                          completedOrders.toString(),
                          Icons.check_circle_outline,
                          Colors.teal,
                        ),
                        _buildStatCard(
                          'Toplam Gelir',
                          '₺${totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Toplam Kullanıcı',
                          totalUsers.toString(),
                          Icons.people,
                          Colors.cyan,
                        ),
                        _buildStatCard(
                          'Aktif Kullanıcı',
                          activeUsers.toString(),
                          Icons.person,
                          Colors.deepOrange,
                        ),
                  ],
                );
              },
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Basit navigasyon butonları
            const Text(
              'Yönetim Paneli',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Basit butonlar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebAdminSimpleProducts(),
                      ),
                    );
                  },
                  icon: Icon(Icons.add),
                  label: Text('Ürün Ekle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebAdminStockManagement(),
                      ),
                    );
                  },
                  icon: Icon(Icons.update),
                  label: Text('Stok Güncelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebAdminReports(),
                      ),
                    );
                  },
                  icon: Icon(Icons.analytics),
                  label: Text('Raporlar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                    ),
                child: Icon(icon, color: color, size: 24),
                  ),
              const Spacer(),
              Text(
                value,
                    style: TextStyle(
                  fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
      ),
    );
  }


  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      final adminService = AdminService();
      
      // Ürün istatistikleri
      final products = await adminService.getProducts().first;
      int totalProducts = products.length;
      int lowStockProducts = products.where((p) => p.stock < 10).length;
      int activeProducts = products.where((p) => p.isActive).length;
      int categories = products.map((p) => p.category).toSet().length;
      
      // Sipariş istatistikleri
      final orders = await adminService.getOrders().first;
      int totalOrders = orders.length;
      int pendingOrders = orders.where((o) => o.status == 'pending').length;
      int completedOrders = orders.where((o) => o.status == 'delivered').length;
      double totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
      
      // Kullanıcı istatistikleri
      final users = await adminService.getUsers().first;
      int totalUsers = users.length;
      int activeUsers = users.where((u) => u.isActive).length;
      
      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'activeProducts': activeProducts,
        'categories': categories,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'lowStockProducts': 0,
        'activeProducts': 0,
        'categories': 0,
        'totalOrders': 0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'totalRevenue': 0.0,
        'totalUsers': 0,
        'activeUsers': 0,
      };
    }
  }
}