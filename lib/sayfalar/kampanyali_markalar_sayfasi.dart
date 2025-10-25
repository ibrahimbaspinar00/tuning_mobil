import 'package:flutter/material.dart';
import '../widgets/optimized_image.dart';

class KampanyaliMarkalarSayfasi extends StatefulWidget {
  const KampanyaliMarkalarSayfasi({super.key});

  @override
  State<KampanyaliMarkalarSayfasi> createState() => _KampanyaliMarkalarSayfasiState();
}

class _KampanyaliMarkalarSayfasiState extends State<KampanyaliMarkalarSayfasi>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Map<String, dynamic>> _brands = [
    {
      'name': 'Bosch',
      'logo': 'https://via.placeholder.com/100x60/FF6B35/FFFFFF?text=BOSCH',
      'discount': '%30',
      'color': Colors.red,
      'description': 'Araç aksesuarlarında %30 indirim',
      'validUntil': '31 Aralık 2024',
      'products': ['Araç Temizlik Seti', 'Kokulu Ağaç', 'Telefon Tutucu'],
    },
    {
      'name': '3M',
      'logo': 'https://via.placeholder.com/100x60/4CAF50/FFFFFF?text=3M',
      'discount': '%25',
      'color': Colors.green,
      'description': 'Güvenlik ürünlerinde %25 indirim',
      'validUntil': '15 Ocak 2025',
      'products': ['Güvenlik Kamerası', 'Park Sensörü', 'Geri Görüş Kamerası'],
    },
    {
      'name': 'Philips',
      'logo': 'https://via.placeholder.com/100x60/2196F3/FFFFFF?text=PHILIPS',
      'discount': '%20',
      'color': Colors.blue,
      'description': 'LED aydınlatma ürünlerinde %20 indirim',
      'validUntil': '28 Şubat 2025',
      'products': ['LED Işık', 'Araç İçi Aydınlatma', 'Gündüz Farları'],
    },
    {
      'name': 'Sony',
      'logo': 'https://via.placeholder.com/100x60/9C27B0/FFFFFF?text=SONY',
      'discount': '%35',
      'color': Colors.purple,
      'description': 'Ses sistemlerinde %35 indirim',
      'validUntil': '10 Mart 2025',
      'products': ['Araç Hoparlörü', 'Bluetooth Alıcı', 'Ses Sistemi'],
    },
    {
      'name': 'Samsung',
      'logo': 'https://via.placeholder.com/100x60/FF9800/FFFFFF?text=SAMSUNG',
      'discount': '%40',
      'color': Colors.orange,
      'description': 'Teknoloji ürünlerinde %40 indirim',
      'validUntil': '5 Nisan 2025',
      'products': ['Araç Şarj Cihazı', 'USB Hub', 'Kablosuz Şarj'],
    },
    {
      'name': 'Apple',
      'logo': 'https://via.placeholder.com/100x60/607D8B/FFFFFF?text=APPLE',
      'discount': '%15',
      'color': Colors.grey,
      'description': 'Apple CarPlay aksesuarlarında %15 indirim',
      'validUntil': '20 Mayıs 2025',
      'products': ['CarPlay Adaptörü', 'Lightning Kablosu', 'Kablosuz Şarj'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kampanyalı Markalar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            // Kampanya Banner
            Container(
              margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple[400]!,
                    Colors.pink[400]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity( 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Özel Marka Kampanyaları',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seçili markalarda büyük indirimler!',
                          style: TextStyle(
                            color: Colors.white.withOpacity( 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Markalar Listesi
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                itemCount: _brands.length,
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  return _buildBrandCard(brand, isSmallScreen, isTablet);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCard(Map<String, dynamic> brand, bool isSmallScreen, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity( 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBrandDetails(brand),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marka Header
                Row(
                  children: [
                    // Marka Logosu
                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: OptimizedImage(
                          imageUrl: brand['logo'],
                          width: 60,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Marka Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: brand['color'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brand['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // İndirim Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: brand['color'],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: brand['color'].withOpacity( 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        brand['discount'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Ürünler
                Text(
                  'Popüler Ürünler:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (brand['products'] as List<String>).map((product) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: brand['color'].withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: brand['color'].withOpacity( 0.3),
                        ),
                      ),
                      child: Text(
                        product,
                        style: TextStyle(
                          fontSize: 12,
                          color: brand['color'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Geçerlilik Tarihi
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Geçerlilik: ${brand['validUntil']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Detayları Gör',
                      style: TextStyle(
                        fontSize: 12,
                        color: brand['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: brand['color'],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBrandDetails(Map<String, dynamic> brand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: OptimizedImage(
                  imageUrl: brand['logo'],
                  width: 40,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                brand['name'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brand['color'],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brand['color'].withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brand['color'].withOpacity( 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: brand['color'], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${brand['discount']} İndirim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brand['color'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              brand['description'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Geçerlilik Tarihi: ${brand['validUntil']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kampanyalı Ürünler:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...(brand['products'] as List<String>).map((product) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: brand['color'],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToBrandProducts(brand);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brand['color'],
              foregroundColor: Colors.white,
            ),
            child: const Text('Ürünleri Gör'),
          ),
        ],
      ),
    );
  }

  void _navigateToBrandProducts(Map<String, dynamic> brand) {
    // Marka ürünlerine yönlendirme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${brand['name']} ürünleri yükleniyor...'),
        backgroundColor: brand['color'],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Tüm Kampanyalar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('En Yüksek İndirim'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Yakında Bitecek'),
              onTap: () => Navigator.pop(context),
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
}
