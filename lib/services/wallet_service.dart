import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletService {
  static const String _balanceKey = 'wallet_balance';
  static const String _transactionsKey = 'wallet_transactions';
  
  static double _currentBalance = 0.0;
  static List<WalletTransaction> _transactions = [];
  
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();
  
  // Getters
  double get currentBalance => _currentBalance;
  List<WalletTransaction> get transactions => List.from(_transactions);
  
  // Initialize wallet
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBalance = prefs.getDouble(_balanceKey) ?? 0.0;
      
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      _transactions = transactionsJson.map((json) => 
        WalletTransaction.fromJson(json)
      ).toList();
      
      debugPrint('Wallet initialized with balance: ${_currentBalance.toStringAsFixed(2)}₺');
    } catch (e) {
      debugPrint('Error initializing wallet: $e');
    }
  }
  
  // Add money to wallet
  Future<bool> addMoney(double amount, String paymentMethod, String description) async {
    try {
      if (amount <= 0) return false;
      
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: TransactionType.deposit,
        paymentMethod: paymentMethod,
        description: description,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
      );
      
      _currentBalance += amount;
      _transactions.insert(0, transaction); // Add to beginning
      
      // Save to storage
      await _saveToStorage();
      
      debugPrint('Added ${amount.toStringAsFixed(2)}₺ to wallet. New balance: ${_currentBalance.toStringAsFixed(2)}₺');
      return true;
    } catch (e) {
      debugPrint('Error adding money to wallet: $e');
      return false;
    }
  }
  
  // Spend money from wallet
  Future<bool> spendMoney(double amount, String description) async {
    try {
      if (amount <= 0 || amount > _currentBalance) return false;
      
      final transaction = WalletTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        type: TransactionType.withdrawal,
        paymentMethod: 'Cüzdan',
        description: description,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
      );
      
      _currentBalance -= amount;
      _transactions.insert(0, transaction);
      
      await _saveToStorage();
      
      debugPrint('Spent ${amount.toStringAsFixed(2)}₺ from wallet. New balance: ${_currentBalance.toStringAsFixed(2)}₺');
      return true;
    } catch (e) {
      debugPrint('Error spending money from wallet: $e');
      return false;
    }
  }
  
  // Get transaction history
  List<WalletTransaction> getTransactionHistory({int? limit}) {
    if (limit != null) {
      return _transactions.take(limit).toList();
    }
    return List.from(_transactions);
  }
  
  // Get recent transactions
  List<WalletTransaction> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
  
  // Check if wallet has sufficient balance
  bool hasSufficientBalance(double amount) {
    return _currentBalance >= amount;
  }
  
  // Save to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_balanceKey, _currentBalance);
      
      final transactionsJson = _transactions.map((t) => t.toJson()).toList();
      await prefs.setStringList(_transactionsKey, transactionsJson);
    } catch (e) {
      debugPrint('Error saving wallet data: $e');
    }
  }
  
  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_balanceKey);
      await prefs.remove(_transactionsKey);
      
      _currentBalance = 0.0;
      _transactions.clear();
      
      debugPrint('Wallet data cleared');
    } catch (e) {
      debugPrint('Error clearing wallet data: $e');
    }
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String paymentMethod;
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  
  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.description,
    required this.timestamp,
    required this.status,
  });
  
  String get formattedAmount {
    final sign = type == TransactionType.deposit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)}₺';
  }
  
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
    };
  }
  
  factory WalletTransaction.fromJson(String jsonString) {
    final Map<String, dynamic> json = {
      'id': '',
      'amount': 0.0,
      'type': 'deposit',
      'paymentMethod': '',
      'description': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'completed',
    };
    
    // Simple JSON parsing (in real app, use proper JSON library)
    final parts = jsonString.split('|');
    if (parts.length >= 7) {
      json['id'] = parts[0];
      json['amount'] = double.tryParse(parts[1]) ?? 0.0;
      json['type'] = parts[2];
      json['paymentMethod'] = parts[3];
      json['description'] = parts[4];
      json['timestamp'] = int.tryParse(parts[5]) ?? DateTime.now().millisecondsSinceEpoch;
      json['status'] = parts[6];
    }
    
    return WalletTransaction(
      id: json['id'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.deposit,
      ),
      paymentMethod: json['paymentMethod'],
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
    );
  }
  
  String toJson() {
    return '${id}|${amount}|${type.toString().split('.').last}|${paymentMethod}|${description}|${timestamp.millisecondsSinceEpoch}|${status.toString().split('.').last}';
  }
}

enum TransactionType {
  deposit,
  withdrawal,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}
