import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product.dart';
import '../model/order.dart' as OrderModel;

class AdvancedPaymentService {
  static final AdvancedPaymentService _instance = AdvancedPaymentService._internal();
  factory AdvancedPaymentService() => _instance;
  AdvancedPaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ödeme yöntemleri
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'Kredi Kartı',
      'icon': '💳',
      'enabled': true,
      'fee': 0.0,
    },
    {
      'id': 'debit_card',
      'name': 'Banka Kartı',
      'icon': '🏦',
      'enabled': true,
      'fee': 0.0,
    },
    {
      'id': 'wallet',
      'name': 'Cüzdan',
      'icon': '💰',
      'enabled': true,
      'fee': 0.0,
    },
    {
      'id': 'installment',
      'name': 'Taksitli Ödeme',
      'icon': '📅',
      'enabled': true,
      'fee': 0.0,
    },
    {
      'id': 'crypto',
      'name': 'Kripto Para',
      'icon': '₿',
      'enabled': false,
      'fee': 0.0,
    },
  ];

  /// Ödeme yöntemlerini getir
  List<Map<String, dynamic>> getPaymentMethods() {
    return _paymentMethods.where((method) => method['enabled']).toList();
  }

  /// Ödeme işlemi başlat
  Future<Map<String, dynamic>> initiatePayment({
    required List<Product> products,
    required String paymentMethod,
    required String userId,
    required Map<String, dynamic> billingInfo,
    String? couponCode,
    bool useWallet = false,
  }) async {
    try {
      // Toplam tutarı hesapla
      final subtotal = _calculateSubtotal(products);
      final shippingCost = _calculateShippingCost(products, billingInfo);
      final couponDiscount = await _calculateCouponDiscount(couponCode, subtotal);
      final taxAmount = _calculateTax(subtotal - couponDiscount);
      final total = subtotal + shippingCost + taxAmount - couponDiscount;

      // Ödeme yöntemi kontrolü
      if (!_isPaymentMethodValid(paymentMethod)) {
        return {
          'success': false,
          'error': 'Geçersiz ödeme yöntemi',
        };
      }

      // Cüzdan kontrolü
      if (useWallet) {
        final walletBalance = await _getWalletBalance(userId);
        if (walletBalance < total) {
          return {
            'success': false,
            'error': 'Cüzdan bakiyesi yetersiz',
          };
        }
      }

      // Ödeme oturumu oluştur
      final paymentSession = await _createPaymentSession({
        'userId': userId,
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'quantity': p.quantity,
        }).toList(),
        'paymentMethod': paymentMethod,
        'billingInfo': billingInfo,
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'taxAmount': taxAmount,
        'couponDiscount': couponDiscount,
        'total': total,
        'couponCode': couponCode,
        'useWallet': useWallet,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'paymentSessionId': paymentSession.id,
        'total': total,
        'paymentUrl': _generatePaymentUrl(paymentMethod, paymentSession.id),
      };
    } catch (e) {
      debugPrint('Initiate payment error: $e');
      return {
        'success': false,
        'error': 'Ödeme işlemi başlatılamadı',
      };
    }
  }

  /// Ödeme işlemini tamamla
  Future<Map<String, dynamic>> completePayment({
    required String paymentSessionId,
    required String transactionId,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final paymentSession = await _firestore
          .collection('payment_sessions')
          .doc(paymentSessionId)
          .get();

      if (!paymentSession.exists) {
        return {
          'success': false,
          'error': 'Ödeme oturumu bulunamadı',
        };
      }

      final sessionData = paymentSession.data()!;
      
      // Ödeme doğrulama
      final paymentVerification = await _verifyPayment(
        sessionData['paymentMethod'],
        transactionId,
        paymentData,
      );

      if (!paymentVerification['success']) {
        return {
          'success': false,
          'error': paymentVerification['error'],
        };
      }

      // Sipariş oluştur
      final order = await _createOrder(sessionData, transactionId);
      
      // Cüzdan güncelle
      if (sessionData['useWallet']) {
        await _updateWalletBalance(
          sessionData['userId'],
          -sessionData['total'],
          'order_payment',
          order.id,
        );
      }

      // Kupon kullan
      if (sessionData['couponCode'] != null) {
        await _useCoupon(sessionData['couponCode'], order.id);
      }

      // Ödeme oturumunu güncelle
      await _firestore.collection('payment_sessions').doc(paymentSessionId).update({
        'status': 'completed',
        'transactionId': transactionId,
        'completedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'orderId': order.id,
        'orderNumber': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      debugPrint('Complete payment error: $e');
      return {
        'success': false,
        'error': 'Ödeme işlemi tamamlanamadı',
      };
    }
  }

  /// Ödeme işlemini iptal et
  Future<bool> cancelPayment(String paymentSessionId) async {
    try {
      await _firestore.collection('payment_sessions').doc(paymentSessionId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Payment cancelled successfully');
      return true;
    } catch (e) {
      debugPrint('Cancel payment error: $e');
      return false;
    }
  }

  /// Taksit seçeneklerini getir
  List<Map<String, dynamic>> getInstallmentOptions(double totalAmount) {
    final options = <Map<String, dynamic>>[];
    
    if (totalAmount >= 100) {
      options.add({
        'installments': 2,
        'monthlyAmount': (totalAmount / 2).toStringAsFixed(2),
        'totalAmount': totalAmount.toStringAsFixed(2),
        'fee': 0.0,
      });
    }
    
    if (totalAmount >= 500) {
      options.add({
        'installments': 3,
        'monthlyAmount': (totalAmount / 3).toStringAsFixed(2),
        'totalAmount': totalAmount.toStringAsFixed(2),
        'fee': 0.0,
      });
    }
    
    if (totalAmount >= 1000) {
      options.add({
        'installments': 6,
        'monthlyAmount': (totalAmount / 6).toStringAsFixed(2),
        'totalAmount': totalAmount.toStringAsFixed(2),
        'fee': totalAmount * 0.02, // %2 komisyon
      });
    }
    
    if (totalAmount >= 2000) {
      options.add({
        'installments': 12,
        'monthlyAmount': (totalAmount / 12).toStringAsFixed(2),
        'totalAmount': totalAmount.toStringAsFixed(2),
        'fee': totalAmount * 0.05, // %5 komisyon
      });
    }
    
    return options;
  }

  /// Ödeme geçmişini getir
  Stream<List<Map<String, dynamic>>> getPaymentHistory(String userId) {
    return _firestore
        .collection('payment_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  /// Yardımcı metodlar
  double _calculateSubtotal(List<Product> products) {
    return products.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }

  double _calculateShippingCost(List<Product> products, Map<String, dynamic> billingInfo) {
    final totalWeight = products.fold(0.0, (sum, product) => sum + 0.5); // Varsayılan ağırlık
    final distance = _calculateDistance(billingInfo);
    
    if (totalWeight > 5) return 25.0; // Ağır paket
    if (distance > 100) return 15.0; // Uzak mesafe
    return 10.0; // Standart kargo
  }

  double _calculateDistance(Map<String, dynamic> billingInfo) {
    // Bu gerçek uygulamada GPS koordinatları kullanılacak
    return 50.0; // Varsayılan mesafe
  }

  Future<double> _calculateCouponDiscount(String? couponCode, double subtotal) async {
    if (couponCode == null) return 0.0;
    
    try {
      final couponSnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (couponSnapshot.docs.isEmpty) return 0.0;
      
      final coupon = couponSnapshot.docs.first.data();
      final discountType = coupon['discountType'];
      final discountValue = coupon['discountValue'].toDouble();
      
      if (discountType == 'percentage') {
        return subtotal * (discountValue / 100);
      } else {
        return discountValue;
      }
    } catch (e) {
      debugPrint('Calculate coupon discount error: $e');
      return 0.0;
    }
  }

  double _calculateTax(double amount) {
    return amount * 0.18; // %18 KDV
  }

  bool _isPaymentMethodValid(String paymentMethod) {
    return _paymentMethods.any((method) => 
        method['id'] == paymentMethod && method['enabled']);
  }

  Future<double> _getWalletBalance(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return (userDoc.data()?['walletBalance'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('Get wallet balance error: $e');
      return 0.0;
    }
  }

  Future<DocumentReference> _createPaymentSession(Map<String, dynamic> data) async {
    return await _firestore.collection('payment_sessions').add(data);
  }

  String _generatePaymentUrl(String paymentMethod, String sessionId) {
    // Bu gerçek uygulamada ödeme sağlayıcısının API'si kullanılacak
    return 'https://payment.example.com/$paymentMethod/$sessionId';
  }

  Future<Map<String, dynamic>> _verifyPayment(
    String paymentMethod,
    String transactionId,
    Map<String, dynamic> paymentData,
  ) async {
    // Bu gerçek uygulamada ödeme sağlayıcısının doğrulama API'si kullanılacak
    return {'success': true, 'error': null};
  }

  Future<OrderModel.Order> _createOrder(Map<String, dynamic> sessionData, String transactionId) async {
    final orderData = {
      'userId': sessionData['userId'],
      'products': sessionData['products'],
      'paymentMethod': sessionData['paymentMethod'],
      'billingInfo': sessionData['billingInfo'],
      'subtotal': sessionData['subtotal'],
      'shippingCost': sessionData['shippingCost'],
      'taxAmount': sessionData['taxAmount'],
      'couponDiscount': sessionData['couponDiscount'],
      'total': sessionData['total'],
      'transactionId': transactionId,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final orderRef = await _firestore.collection('orders').add(orderData);
    
    return OrderModel.Order(
      id: orderRef.id,
      products: sessionData['products'],
      totalAmount: sessionData['total'],
      orderDate: DateTime.now(),
      status: 'confirmed',
      customerName: sessionData['billingInfo']['name'] ?? '',
      customerEmail: sessionData['billingInfo']['email'] ?? '',
      customerPhone: sessionData['billingInfo']['phone'] ?? '',
      shippingAddress: sessionData['billingInfo']['address'] ?? '',
    );
  }

  Future<void> _updateWalletBalance(
    String userId,
    double amount,
    String type,
    String referenceId,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'walletBalance': FieldValue.increment(amount),
    });

    await _firestore.collection('wallet_transactions').add({
      'userId': userId,
      'amount': amount,
      'type': type,
      'referenceId': referenceId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _useCoupon(String couponCode, String orderId) async {
    await _firestore.collection('coupons').where('code', isEqualTo: couponCode).get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.update({
          'usedCount': FieldValue.increment(1),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
