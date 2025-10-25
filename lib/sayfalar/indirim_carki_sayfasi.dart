import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/discount_wheel_service.dart';

class IndirimCarkiSayfasi extends StatefulWidget {
  const IndirimCarkiSayfasi({super.key});

  @override
  State<IndirimCarkiSayfasi> createState() => _IndirimCarkiSayfasiState();
}

class _IndirimCarkiSayfasiState extends State<IndirimCarkiSayfasi>
    with TickerProviderStateMixin {
  final DiscountWheelService _wheelService = DiscountWheelService();
  
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  
  bool _isSpinning = false;
  WheelReward? _lastReward;
  int _remainingSpins = 0;
  String _countdownString = '00:00:00';
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWheelData();
    _startCountdownTimer();
  }
  
  void _initializeAnimations() {
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    ));
    
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
        });
      }
    });
  }
  
  Future<void> _loadWheelData() async {
    try {
      await _wheelService.initialize();
      setState(() {
        _remainingSpins = _wheelService.remainingSpins;
      });
    } catch (e) {
      _showErrorDialog('Çark verileri yüklenirken hata oluştu: $e');
    }
  }
  
  void _startCountdownTimer() {
    // Her saniye geri sayımı güncelle
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdownString = _wheelService.getCountdownString();
        });
        return true;
      }
      return false;
    });
  }
  
  String _getCouponCodeForReward(WheelReward reward) {
    // Aktif ödüller arasından bu ödüle ait kupon kodunu bul
    final activeRewards = _wheelService.getActiveRewards();
    
    // Önce tam eşleşme ara
    for (final activeReward in activeRewards) {
      if (activeReward.id == reward.id && activeReward.isActive) {
        return activeReward.couponCode ?? '';
      }
    }
    
    // Tam eşleşme bulunamazsa, en son eklenen aktif ödülü al
    if (activeRewards.isNotEmpty) {
      final lastActiveReward = activeRewards.last;
      if (lastActiveReward.isActive) {
        return lastActiveReward.couponCode ?? '';
      }
    }
    
    // Hiç aktif ödül yoksa, yeni kupon kodu üret
    return _generateTemporaryCouponCode(reward);
  }
  
  String _generateTemporaryCouponCode(WheelReward reward) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final random = math.Random().nextInt(9000) + 1000;
    return '${reward.id.toUpperCase()}$timestamp$random';
  }
  
  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'İndirim Çarkı',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showRewardHistory,
            icon: const Icon(Icons.history),
            tooltip: 'Ödül Geçmişi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // Çark Bilgileri
            _buildWheelInfo(),
            const SizedBox(height: 24),
            
            // Çark
            _buildWheel(),
            const SizedBox(height: 24),
            
            // Çevir Butonu
            _buildSpinButton(),
            const SizedBox(height: 24),
            
            // Son Ödül
            if (_lastReward != null) _buildLastReward(),
            
            // Ödül Listesi
            _buildRewardList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWheelInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[400]!,
            Colors.orange[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity( 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.casino,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Günlük İndirim Çarkı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$_remainingSpins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Kalan Hak',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${_wheelService.totalSpins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Toplam Çevirme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_remainingSpins == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity( 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'Sonraki çark için kalan süre:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _countdownString,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildWheel() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity( 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _spinAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _spinAnimation.value * 2 * math.pi * 5, // 5 tam tur
            child: CustomPaint(
              size: const Size(300, 300),
              painter: WheelPainter(_wheelService.rewards),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSpinButton() {
    final canSpin = _remainingSpins > 0 && !_isSpinning;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: canSpin
            ? LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              )
            : null,
        color: canSpin ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: canSpin
            ? [
                BoxShadow(
                  color: Colors.orange.withOpacity( 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSpin ? _spinWheel : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isSpinning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _remainingSpins > 0 ? Icons.casino : Icons.schedule,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _remainingSpins > 0 
                            ? 'Çarkı Çevir!' 
                            : 'Yarın Tekrar Dene',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLastReward() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.celebration,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son Ödülünüz',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _lastReward!.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _lastReward!.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Kupon Kodunuz:',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _getCouponCodeForReward(_lastReward!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _useReward(_lastReward!),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Kullan'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRewardList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Mevcut Ödüller',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._wheelService.rewards.map((reward) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: reward.color.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: reward.color.withOpacity( 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: reward.color.withOpacity( 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      reward.icon,
                      color: reward.color,
                      size: 20,
                    ),
                  ),
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
                          reward.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(reward.probability * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: reward.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Future<void> _spinWheel() async {
    setState(() {
      _isSpinning = true;
    });
    
    // Çark animasyonunu başlat
    _spinController.forward(from: 0);
    
    // 2 saniye sonra sonucu al
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final result = await _wheelService.spinWheel();
      
      if (result.success && result.reward != null) {
        setState(() {
          _lastReward = result.reward;
          _remainingSpins = _wheelService.remainingSpins;
        });
        
        _showRewardDialog(result.reward!);
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Çark çevrilirken hata oluştu: $e');
    }
  }
  
  void _showRewardDialog(WheelReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('Tebrikler!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: reward.color.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: reward.color.withOpacity( 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    reward.icon,
                    color: reward.color,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reward.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: reward.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu ödülü hemen kullanabilirsiniz!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useReward(reward);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: reward.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hemen Kullan'),
          ),
        ],
      ),
    );
  }
  
  void _useReward(WheelReward reward) {
    _wheelService.useReward(reward.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reward.name} kullanıldı!'),
        backgroundColor: reward.color,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
  
  void _showRewardHistory() {
    // Ödül geçmişi sayfası
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardHistoryPage(),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<WheelReward> rewards;
  
  WheelPainter(this.rewards);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Çark dilimlerini çiz
    for (int i = 0; i < rewards.length; i++) {
      final startAngle = (i * 2 * math.pi) / rewards.length;
      final sweepAngle = (2 * math.pi) / rewards.length;
      
      final paint = Paint()
        ..color = rewards[i].color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Dilim kenarları
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      
      // Metin çiz
      final textPainter = TextPainter(
        text: TextSpan(
          text: rewards[i].name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final textAngle = startAngle + sweepAngle / 2;
      final textX = center.dx + (radius * 0.7) * math.cos(textAngle);
      final textY = center.dy + (radius * 0.7) * math.sin(textAngle);
      
      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    
    // Merkez daire
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 30, centerPaint);
    
    // Merkez ikon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '🎯',
        style: TextStyle(fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    );
    
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(center.dx - iconPainter.width / 2, center.dy - iconPainter.height / 2),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  final DiscountWheelService _wheelService = DiscountWheelService();
  List<ActiveReward> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewardHistory();
  }

  Future<void> _loadRewardHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _wheelService.initialize();
      setState(() {
        _rewards = _wheelService.getAllRewards();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödül Geçmişi'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rewards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz ödül kazanmadınız',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Çarkı çevirerek ödül kazanmaya başlayın!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity( 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: reward.color.withOpacity( 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              reward.icon,
                              color: reward.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      reward.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: reward.color,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: reward.isActive 
                                            ? Colors.green[100] 
                                            : reward.isUsed 
                                                ? Colors.blue[100] 
                                                : Colors.red[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        reward.isActive 
                                            ? 'Aktif' 
                                            : reward.isUsed 
                                                ? 'Kullanıldı' 
                                                : 'Süresi Doldu',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: reward.isActive 
                                              ? Colors.green[700] 
                                              : reward.isUsed 
                                                  ? Colors.blue[700] 
                                                  : Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reward.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (reward.isActive) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kalan süre: ${reward.timeRemainingString}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (reward.isUsed && reward.usedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kullanıldı: ${_formatDate(reward.usedAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
