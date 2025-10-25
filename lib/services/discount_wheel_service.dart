import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DiscountWheelService {
  static const String _lastSpinDateKey = 'last_spin_date';
  static const String _spinCountKey = 'spin_count';
  static const String _totalSpinsKey = 'total_spins';
  static const String _activeRewardsKey = 'active_rewards';
  static const String _usedCouponsKey = 'used_coupons';
  
  // Singleton pattern
  static final DiscountWheelService _instance = DiscountWheelService._internal();
  factory DiscountWheelService() => _instance;
  DiscountWheelService._internal();
  
  // Günlük çark hakları
  int _dailySpins = 1;
  int _remainingSpins = 1;
  DateTime? _lastSpinDate;
  int _totalSpins = 0;
  
  // Aktif ödüller (24 saat geçerli)
  List<ActiveReward> _activeRewards = [];
  
  // Kullanılan kupon kodları
  Set<String> _usedCouponCodes = {};
  
  // Çark ödülleri
  final List<WheelReward> _rewards = [
    WheelReward(
      id: 'discount_5',
      name: '%5 İndirim',
      description: 'Tüm ürünlerde %5 indirim',
      discountPercent: 5.0,
      color: Colors.blue,
      icon: Icons.local_offer,
      probability: 0.25, // %25 şans
      needsCoupon: true,
    ),
    WheelReward(
      id: 'discount_10',
      name: '%10 İndirim',
      description: 'Tüm ürünlerde %10 indirim',
      discountPercent: 10.0,
      color: Colors.green,
      icon: Icons.local_offer,
      probability: 0.20, // %20 şans
      needsCoupon: true,
    ),
    WheelReward(
      id: 'discount_15',
      name: '%15 İndirim',
      description: 'Tüm ürünlerde %15 indirim',
      discountPercent: 15.0,
      color: Colors.orange,
      icon: Icons.local_offer,
      probability: 0.15, // %15 şans
      needsCoupon: true,
    ),
    WheelReward(
      id: 'discount_20',
      name: '%20 İndirim',
      description: 'Tüm ürünlerde %20 indirim',
      discountPercent: 20.0,
      color: Colors.red,
      icon: Icons.local_offer,
      probability: 0.10, // %10 şans
      needsCoupon: true,
    ),
    WheelReward(
      id: 'discount_25',
      name: '%25 İndirim',
      description: 'Tüm ürünlerde %25 indirim',
      discountPercent: 25.0,
      color: Colors.purple,
      icon: Icons.local_offer,
      probability: 0.08, // %8 şans
      needsCoupon: true,
    ),
    WheelReward(
      id: 'free_shipping',
      name: 'Ücretsiz Kargo',
      description: 'Siparişlerinizde ücretsiz kargo',
      discountPercent: 0.0,
      color: Colors.teal,
      icon: Icons.local_shipping,
      probability: 0.12, // %12 şans
      needsCoupon: false, // Ücretsiz kargo için kupon kodu yok
    ),
    WheelReward(
      id: 'cashback_50',
      name: '50₺ Nakit İade',
      description: '50₺ nakit iade kazanın',
      discountPercent: 0.0,
      color: Colors.amber,
      icon: Icons.money,
      probability: 0.05, // %5 şans
      needsCoupon: false, // Para ödülü otomatik cüzdana geçer
      cashAmount: 50.0,
    ),
    WheelReward(
      id: 'cashback_100',
      name: '100₺ Nakit İade',
      description: '100₺ nakit iade kazanın',
      discountPercent: 0.0,
      color: Colors.amber[700]!,
      icon: Icons.money,
      probability: 0.03, // %3 şans
      needsCoupon: false, // Para ödülü otomatik cüzdana geçer
      cashAmount: 100.0,
    ),
    WheelReward(
      id: 'try_again',
      name: 'Tekrar Dene',
      description: 'Bir kez daha çevirme hakkı',
      discountPercent: 0.0,
      color: Colors.grey,
      icon: Icons.refresh,
      probability: 0.02, // %2 şans
      needsCoupon: false,
    ),
  ];
  
  // Getters
  int get remainingSpins => _remainingSpins;
  int get totalSpins => _totalSpins;
  List<WheelReward> get rewards => List.from(_rewards);
  
  // Initialize service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Son çark tarihini kontrol et
      final lastSpinString = prefs.getString(_lastSpinDateKey);
      if (lastSpinString != null) {
        _lastSpinDate = DateTime.parse(lastSpinString);
        
        // Eğer bugün değilse, çark haklarını yenile
        final now = DateTime.now();
        if (_lastSpinDate!.day != now.day || 
            _lastSpinDate!.month != now.month || 
            _lastSpinDate!.year != now.year) {
          _remainingSpins = _dailySpins;
          _lastSpinDate = now;
          await _saveToStorage();
        }
      } else {
        _remainingSpins = _dailySpins;
        _lastSpinDate = DateTime.now();
        await _saveToStorage();
      }
      
      _totalSpins = prefs.getInt(_totalSpinsKey) ?? 0;
      
      // Aktif ödülleri yükle
      await _loadActiveRewards();
      
      debugPrint('DiscountWheelService initialized. Remaining spins: $_remainingSpins');
    } catch (e) {
      debugPrint('Error initializing DiscountWheelService: $e');
    }
  }
  
  // Çark çevirme
  Future<WheelResult> spinWheel() async {
    if (_remainingSpins <= 0) {
      return WheelResult(
        success: false,
        message: 'Bugünkü çark hakkınız bitti. Yarın tekrar deneyin!',
        reward: null,
        couponCode: null,
      );
    }
    
    try {
      // Rastgele ödül seç
      final selectedReward = _selectRandomReward();
      
      String? couponCode;
      
      // Sadece kupon gerektiren ödüller için kod üret
      if (selectedReward.needsCoupon) {
        couponCode = _generateSecureCouponCode();
      }
      
      // Aktif ödül olarak ekle (24 saat geçerli)
      final activeReward = ActiveReward(
        id: '${selectedReward.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: selectedReward.name,
        description: selectedReward.description,
        discountPercent: selectedReward.discountPercent,
        color: selectedReward.color,
        icon: selectedReward.icon,
        earnedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        couponCode: couponCode,
        cashAmount: selectedReward.cashAmount,
        isAutoApplied: !selectedReward.needsCoupon, // Kupon gerektirmeyenler otomatik uygulanır
      );
      
      _activeRewards.add(activeReward);
      
      // Çark hakkını azalt
      _remainingSpins--;
      _totalSpins++;
      
      // Kaydet
      await _saveToStorage();
      
      debugPrint('Wheel spun! Selected reward: ${selectedReward.name}');
      
      return WheelResult(
        success: true,
        message: _getRewardMessage(selectedReward),
        reward: selectedReward,
        couponCode: couponCode,
      );
    } catch (e) {
      debugPrint('Error spinning wheel: $e');
      return WheelResult(
        success: false,
        message: 'Çark çevrilirken hata oluştu. Lütfen tekrar deneyin.',
        reward: null,
        couponCode: null,
      );
    }
  }
  
  // Ödül mesajı
  String _getRewardMessage(WheelReward reward) {
    if (reward.id == 'try_again') {
      return 'Tebrikler! Bir kez daha çevirme hakkı kazandınız!';
    } else if (reward.id.startsWith('cashback_')) {
      return 'Tebrikler! ${reward.cashAmount}₺ cüzdanınıza yüklendi!';
    } else if (reward.id == 'free_shipping') {
      return 'Tebrikler! Ücretsiz kargo hakkınız aktif!';
    } else {
      return 'Tebrikler! ${reward.name} kazandınız! 24 saat geçerli.';
    }
  }
  
  // Rastgele ödül seçimi
  WheelReward _selectRandomReward() {
    final random = Random();
    final randomValue = random.nextDouble();
    double cumulativeProbability = 0.0;
    
    for (final reward in _rewards) {
      cumulativeProbability += reward.probability;
      if (randomValue <= cumulativeProbability) {
        return reward;
      }
    }
    
    // Fallback - ilk ödülü döndür
    return _rewards.first;
  }
  
  // Güvenli kupon kodu üret
  String _generateSecureCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    // 6 karakter rastgele kod
    final randomPart = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    
    return '${randomPart}${timestamp}';
  }
  
  // Çark hakkı var mı?
  bool canSpin() {
    return _remainingSpins > 0;
  }
  
  // Kalan süreyi hesapla (bir sonraki gün için)
  Duration getTimeUntilNextSpin() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }
  
  // Geri sayım string'i
  String getCountdownString() {
    final duration = getTimeUntilNextSpin();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  // Aktif ödülleri getir
  List<ActiveReward> getActiveRewards() {
    // Süresi dolmuş ödülleri temizle
    _activeRewards.removeWhere((reward) => reward.isExpired);
    return _activeRewards.where((reward) => reward.isActive).toList();
  }
  
  // Tüm ödül geçmişi (aktif + kullanılmış + süresi dolmuş)
  List<ActiveReward> getAllRewards() {
    return List.from(_activeRewards);
  }
  
  // Ödül kullan
  bool useReward(String rewardId) {
    final rewardIndex = _activeRewards.indexWhere((reward) => reward.id == rewardId);
    if (rewardIndex != -1 && _activeRewards[rewardIndex].isActive) {
      _activeRewards[rewardIndex] = ActiveReward(
        id: _activeRewards[rewardIndex].id,
        name: _activeRewards[rewardIndex].name,
        description: _activeRewards[rewardIndex].description,
        discountPercent: _activeRewards[rewardIndex].discountPercent,
        color: _activeRewards[rewardIndex].color,
        icon: _activeRewards[rewardIndex].icon,
        earnedAt: _activeRewards[rewardIndex].earnedAt,
        expiresAt: _activeRewards[rewardIndex].expiresAt,
        isUsed: true,
        usedAt: DateTime.now(),
        couponCode: _activeRewards[rewardIndex].couponCode,
        cashAmount: _activeRewards[rewardIndex].cashAmount,
        isAutoApplied: _activeRewards[rewardIndex].isAutoApplied,
      );
      return true;
    }
    return false;
  }
  
  // Kupon kodu doğrula
  bool validateCouponCode(String code) {
    if (_usedCouponCodes.contains(code)) {
      return false; // Zaten kullanılmış
    }
    
    // Aktif ödüller arasında ara
    final activeReward = _activeRewards.firstWhere(
      (reward) => reward.couponCode == code && reward.isActive,
      orElse: () => ActiveReward(
        id: '',
        name: '',
        description: '',
        discountPercent: 0,
        color: Colors.grey,
        icon: Icons.error,
        earnedAt: DateTime.now(),
        expiresAt: DateTime.now(),
        couponCode: '',
      ),
    );
    
    return activeReward.id.isNotEmpty;
  }
  
  // Kupon kodu kullan
  ActiveReward? useCouponCode(String code) {
    if (_usedCouponCodes.contains(code)) {
      return null; // Zaten kullanılmış
    }
    
    final rewardIndex = _activeRewards.indexWhere(
      (reward) => reward.couponCode == code && reward.isActive,
    );
    
    if (rewardIndex == -1) {
      return null; // Geçersiz kod
    }
    
    // Kupon kodunu kullanıldı olarak işaretle
    _usedCouponCodes.add(code);
    
    // Ödülü kullanıldı olarak işaretle
    _activeRewards[rewardIndex] = ActiveReward(
      id: _activeRewards[rewardIndex].id,
      name: _activeRewards[rewardIndex].name,
      description: _activeRewards[rewardIndex].description,
      discountPercent: _activeRewards[rewardIndex].discountPercent,
      color: _activeRewards[rewardIndex].color,
      icon: _activeRewards[rewardIndex].icon,
      earnedAt: _activeRewards[rewardIndex].earnedAt,
      expiresAt: _activeRewards[rewardIndex].expiresAt,
      isUsed: true,
      usedAt: DateTime.now(),
      couponCode: _activeRewards[rewardIndex].couponCode,
      cashAmount: _activeRewards[rewardIndex].cashAmount,
      isAutoApplied: _activeRewards[rewardIndex].isAutoApplied,
    );
    
    return _activeRewards[rewardIndex];
  }
  
  // Aktif ödülleri yükle
  Future<void> _loadActiveRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rewardsJson = prefs.getString(_activeRewardsKey);
      if (rewardsJson != null) {
        // JSON'dan ödülleri yükle (basit implementasyon)
        _activeRewards = [];
      }
      
      final usedCouponsJson = prefs.getString(_usedCouponsKey);
      if (usedCouponsJson != null) {
        // JSON'dan kullanılan kuponları yükle
        _usedCouponCodes = {};
      }
    } catch (e) {
      debugPrint('Error loading active rewards: $e');
    }
  }
  
  // Storage'a kaydet
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSpinDateKey, _lastSpinDate!.toIso8601String());
      await prefs.setInt(_spinCountKey, _remainingSpins);
      await prefs.setInt(_totalSpinsKey, _totalSpins);
      
      // Aktif ödülleri kaydet (basit implementasyon)
      // Gerçek uygulamada JSON serialization kullanılacak
      
    } catch (e) {
      debugPrint('Error saving wheel data: $e');
    }
  }
  
  // Test için tüm verileri temizle
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSpinDateKey);
      await prefs.remove(_spinCountKey);
      await prefs.remove(_totalSpinsKey);
      await prefs.remove(_activeRewardsKey);
      await prefs.remove(_usedCouponsKey);
      
      _remainingSpins = _dailySpins;
      _lastSpinDate = DateTime.now();
      _totalSpins = 0;
      _activeRewards.clear();
      _usedCouponCodes.clear();
      
      debugPrint('DiscountWheelService data cleared');
    } catch (e) {
      debugPrint('Error clearing wheel data: $e');
    }
  }
}

class WheelReward {
  final String id;
  final String name;
  final String description;
  final double discountPercent;
  final Color color;
  final IconData icon;
  final double probability;
  final bool needsCoupon; // Kupon kodu gerekiyor mu?
  final double? cashAmount; // Para ödülü miktarı
  
  WheelReward({
    required this.id,
    required this.name,
    required this.description,
    required this.discountPercent,
    required this.color,
    required this.icon,
    required this.probability,
    required this.needsCoupon,
    this.cashAmount,
  });
}

class WheelResult {
  final bool success;
  final String message;
  final WheelReward? reward;
  final String? couponCode;
  
  WheelResult({
    required this.success,
    required this.message,
    this.reward,
    this.couponCode,
  });
}

class ActiveReward {
  final String id;
  final String name;
  final String description;
  final double discountPercent;
  final Color color;
  final IconData icon;
  final DateTime earnedAt;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? couponCode;
  final double? cashAmount;
  final bool isAutoApplied; // Otomatik uygulanan ödül mü?

  ActiveReward({
    required this.id,
    required this.name,
    required this.description,
    required this.discountPercent,
    required this.color,
    required this.icon,
    required this.earnedAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedAt,
    this.couponCode,
    this.cashAmount,
    this.isAutoApplied = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired && !isUsed;
  
  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }
  
  String get timeRemainingString {
    final duration = timeRemaining;
    if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes % 60}dk';
    } else {
      return '${duration.inMinutes}dk';
    }
  }
}