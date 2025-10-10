import 'package:flutter/material.dart';

class BildirimAyarlariSayfasi extends StatefulWidget {
  const BildirimAyarlariSayfasi({super.key});

  @override
  State<BildirimAyarlariSayfasi> createState() => _BildirimAyarlariSayfasiState();
}

class _BildirimAyarlariSayfasiState extends State<BildirimAyarlariSayfasi> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;
  bool _priceAlerts = true;
  bool _newProductAlerts = true;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[50]!, Colors.grey[50]!],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Genel Bildirimler
                _buildNotificationSection(
                  title: 'Genel Bildirimler',
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      title: 'Push Bildirimleri',
                      subtitle: 'Uygulama içi bildirimler',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'E-posta Bildirimleri',
                      subtitle: 'E-posta ile bildirim al',
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'SMS Bildirimleri',
                      subtitle: 'SMS ile bildirim al',
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Sipariş Bildirimleri
                _buildNotificationSection(
                  title: 'Sipariş Bildirimleri',
                  icon: Icons.shopping_bag,
                  children: [
                    _buildSwitchTile(
                      title: 'Sipariş Güncellemeleri',
                      subtitle: 'Sipariş durumu değişiklikleri',
                      value: _orderUpdates,
                      onChanged: (value) {
                        setState(() {
                          _orderUpdates = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Güvenlik Bildirimleri',
                      subtitle: 'Hesap güvenliği uyarıları',
                      value: _securityAlerts,
                      onChanged: (value) {
                        setState(() {
                          _securityAlerts = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Ürün Bildirimleri
                _buildNotificationSection(
                  title: 'Ürün Bildirimleri',
                  icon: Icons.shopping_cart,
                  children: [
                    _buildSwitchTile(
                      title: 'Fiyat Uyarıları',
                      subtitle: 'Favori ürünlerde fiyat değişiklikleri',
                      value: _priceAlerts,
                      onChanged: (value) {
                        setState(() {
                          _priceAlerts = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Yeni Ürün Bildirimleri',
                      subtitle: 'Yeni ürün eklemeleri',
                      value: _newProductAlerts,
                      onChanged: (value) {
                        setState(() {
                          _newProductAlerts = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Pazarlama Bildirimleri
                _buildNotificationSection(
                  title: 'Pazarlama Bildirimleri',
                  icon: Icons.campaign,
                  children: [
                    _buildSwitchTile(
                      title: 'Promosyon Teklifleri',
                      subtitle: 'İndirim ve kampanya duyuruları',
                      value: _promotionalOffers,
                      onChanged: (value) {
                        setState(() {
                          _promotionalOffers = value;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Bildirim Zamanları
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bildirim Zamanları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTimeTile(
                        title: 'Günlük Bildirim Saati',
                        subtitle: '09:00 - 18:00 arası',
                        onTap: () {
                          _showTimePicker('Günlük Bildirim Saati');
                        },
                      ),
                      _buildTimeTile(
                        title: 'Sessiz Saatler',
                        subtitle: '22:00 - 08:00 arası',
                        onTap: () {
                          _showTimePicker('Sessiz Saatler');
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ayarları Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.orange[600], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange[600],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showTimePicker(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: const Text('Zaman seçici özelliği geliştiriliyor...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bildirim ayarları başarıyla kaydedildi'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
