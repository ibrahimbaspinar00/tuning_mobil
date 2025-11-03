import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../model/notification.dart';
import '../services/notification_service.dart';
import '../widgets/error_handler.dart';
import '../config/app_routes.dart';

class BildirimlerSayfasi extends StatefulWidget {
  const BildirimlerSayfasi({super.key});

  @override
  State<BildirimlerSayfasi> createState() => _BildirimlerSayfasiState();
}

class _BildirimlerSayfasiState extends State<BildirimlerSayfasi> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Tümünü Okundu İşaretle',
          ),
        ],
      ),
      body: _auth.currentUser == null
          ? _buildGuestView()
          : _buildNotificationsList(),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bildirimleri görmek için giriş yapın',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              AppRoutes.navigateToLogin(context);
            },
            icon: const Icon(Icons.login),
            label: const Text('Giriş Yap'),
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

  Widget _buildNotificationsList() {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Bildirimler yüklenirken hata oluştu',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Henüz bildiriminiz yok',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kampanyalar ve sipariş güncellemeleri\nburada görünecek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }


  Widget _buildNotificationCard(AppNotification notification) {
    final isCouponNotification = notification.data?['coupon_code'] != null;
    final isDiscountNotification = notification.data?['discount'] != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? Colors.white : Colors.blue[50],
            border: notification.isRead 
                ? null 
                : Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.w500 
                                      : FontWeight.bold,
                                  color: notification.isRead 
                                      ? Colors.grey[700] 
                                      : Colors.grey[900],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            _buildTypeChip(notification.type),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Kupon kodu veya indirim bilgisi
              if (isCouponNotification || isDiscountNotification) ...[
                const SizedBox(height: 12),
                _buildCouponSection(notification),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection(AppNotification notification) {
    final couponCode = notification.data?['coupon_code'];
    final discount = notification.data?['discount'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[100]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer,
            color: Colors.orange[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (couponCode != null) ...[
                  Text(
                    'Kupon Kodu: $couponCode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sepetinizde kullanabilirsiniz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                ] else if (discount != null) ...[
                  Text(
                    '%$discount İndirim',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Belirtilen kategoride geçerli',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (couponCode != null)
            IconButton(
              onPressed: () => _copyCouponCode(couponCode),
              icon: Icon(
                Icons.copy,
                color: Colors.orange[700],
                size: 18,
              ),
              tooltip: 'Kodu Kopyala',
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'order':
        iconData = Icons.shopping_bag;
        iconColor = Colors.green;
        break;
      case 'promotion':
        iconData = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      case 'stock':
        iconData = Icons.inventory;
        iconColor = Colors.red;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.blue;
        break;
      case 'shipping':
        iconData = Icons.local_shipping;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'order':
        label = 'Sipariş';
        color = Colors.green;
        break;
      case 'promotion':
        label = 'Promosyon';
        color = Colors.orange;
        break;
      case 'stock':
        label = 'Stok';
        color = Colors.red;
        break;
      case 'payment':
        label = 'Ödeme';
        color = Colors.blue;
        break;
      case 'shipping':
        label = 'Kargo';
        color = Colors.purple;
        break;
      default:
        label = 'Sistem';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _onNotificationTap(AppNotification notification) async {
    // Bildirimi okundu olarak işaretle
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    // Action URL varsa navigate et
    if (notification.actionUrl != null) {
      // TODO: Navigation logic
      print('Navigate to: ${notification.actionUrl}');
    }

    // Data varsa işle
    if (notification.data != null) {
      final action = notification.data!['action'];
      switch (action) {
        case 'view_order':
          // TODO: Navigate to order details
          break;
        case 'view_product':
          // TODO: Navigate to product details
          break;
        default:
          break;
      }
    }
  }

  void _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Bildirimler işaretlenemedi: $e');
      }
    }
  }

  void _copyCouponCode(String couponCode) async {
    await Clipboard.setData(ClipboardData(text: couponCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kupon kodu kopyalandı: $couponCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Sepete Git',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.main);
            },
          ),
        ),
      );
    }
  }
}
