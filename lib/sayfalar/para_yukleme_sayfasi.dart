import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class ParaYuklemeSayfasi extends StatefulWidget {
  const ParaYuklemeSayfasi({super.key});

  @override
  State<ParaYuklemeSayfasi> createState() => _ParaYuklemeSayfasiState();
}

class _ParaYuklemeSayfasiState extends State<ParaYuklemeSayfasi>
    with TickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  
  double _selectedAmount = 0.0;
  String _selectedPaymentMethod = 'Kredi Kartı';
  bool _isLoading = false;
  bool _isProcessing = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 50.0, 'label': '50₺', 'popular': false},
    {'amount': 100.0, 'label': '100₺', 'popular': true},
    {'amount': 250.0, 'label': '250₺', 'popular': false},
    {'amount': 500.0, 'label': '500₺', 'popular': true},
    {'amount': 1000.0, 'label': '1000₺', 'popular': false},
    {'amount': 2000.0, 'label': '2000₺', 'popular': false},
  ];
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'Kredi Kartı',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'description': 'Visa, Mastercard, American Express',
      'fee': 0.0,
    },
    {
      'id': 'debit_card',
      'name': 'Banka Kartı',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'description': 'Tüm banka kartları',
      'fee': 0.0,
    },
    {
      'id': 'bank_transfer',
      'name': 'Havale/EFT',
      'icon': Icons.account_balance_wallet,
      'color': Colors.orange,
      'description': 'Banka havalesi',
      'fee': 0.0,
    },
    {
      'id': 'mobile_payment',
      'name': 'Mobil Ödeme',
      'icon': Icons.phone_android,
      'color': Colors.purple,
      'description': 'PayPal, Apple Pay, Google Pay',
      'fee': 0.0,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWalletData();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }
  
  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _walletService.initialize();
      setState(() {});
    } catch (e) {
      _showErrorDialog('Cüzdan verileri yüklenirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Para Yükle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showTransactionHistory,
            icon: const Icon(Icons.history),
            tooltip: 'İşlem Geçmişi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cüzdan Bakiyesi
                      _buildWalletBalance(),
                      const SizedBox(height: 24),
                      
                      // Miktar Seçimi
                      _buildAmountSelection(),
                      const SizedBox(height: 24),
                      
                      // Ödeme Yöntemi
                      _buildPaymentMethodSelection(),
                      const SizedBox(height: 32),
                      
                      // Yükle Butonu
                      _buildLoadButton(),
                      const SizedBox(height: 24),
                      
                      // Güvenlik Bilgileri
                      _buildSecurityInfo(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildWalletBalance() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[400]!,
            Colors.green[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity( 0.3),
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
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Cüzdan Bakiyesi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_walletService.currentBalance.toStringAsFixed(2)} ₺',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Son güncelleme: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              color: Colors.white.withOpacity( 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAmountSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.attach_money, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Yüklenecek Miktar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Manuel Miktar Girişi
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '₺ ',
              prefixIcon: Icon(Icons.money, color: Colors.green[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _selectedAmount = double.tryParse(value) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Hızlı Miktar Butonları
          const Text(
            'Hızlı Seçim',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((item) {
              final isSelected = _selectedAmount == item['amount'];
              final isPopular = item['popular'] as bool;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = item['amount'] as double;
                    _amountController.text = item['amount'].toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity( 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star,
                          color: isSelected ? Colors.white : Colors.orange[600],
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.payment, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Ödeme Yöntemi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method['name'];
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = method['name'] as String;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? (method['color'] as Color).withOpacity( 0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? method['color'] as Color : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (method['color'] as Color).withOpacity( 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: method['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? method['color'] as Color : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: method['color'] as Color,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildLoadButton() {
    final isValid = _selectedAmount > 0 && _selectedAmount <= 10000;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isValid
            ? LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              )
            : null,
        color: isValid ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isValid
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity( 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isValid && !_isProcessing ? _processPayment : null,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isProcessing
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
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedAmount.toStringAsFixed(2)}₺ Yükle',
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
  
  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Güvenlik Bilgileri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Tüm ödemeler SSL ile şifrelenir\n• Kart bilgileriniz saklanmaz\n• 7/24 güvenli ödeme',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      final success = await _walletService.addMoney(
        _selectedAmount,
        _selectedPaymentMethod,
        'Para yükleme - ${_selectedPaymentMethod}',
      );
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Para yükleme işlemi başarısız oldu.');
      }
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Text('Başarılı!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedAmount.toStringAsFixed(2)}₺ cüzdanınıza başarıyla yüklendi!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Yeni Bakiye: ${_walletService.currentBalance.toStringAsFixed(2)}₺',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
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
  
  void _showTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryPage(),
      ),
    );
  }
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final WalletService _walletService = WalletService();
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _walletService.initialize();
      setState(() {
        _transactions = _walletService.getTransactionHistory();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      appBar: AppBar(
        title: const Text('İşlem Geçmişi'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz işlem yapılmamış',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
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
                              color: transaction.type == TransactionType.deposit
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              transaction.type == TransactionType.deposit
                                  ? Icons.add
                                  : Icons.remove,
                              color: transaction.type == TransactionType.deposit
                                  ? Colors.green[600]
                                  : Colors.red[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  transaction.formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            transaction.formattedAmount,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: transaction.type == TransactionType.deposit
                                  ? Colors.green[600]
                                  : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
