import 'package:flutter/material.dart';

class OdemeYontemi {
  final String id;
  final String type; // 'card', 'bank', 'digital'
  final String name;
  final String number;
  final String expiryDate;
  final bool isDefault;

  OdemeYontemi({
    required this.id,
    required this.type,
    required this.name,
    required this.number,
    required this.expiryDate,
    this.isDefault = false,
  });
}

class OdemeYontemleriSayfasi extends StatefulWidget {
  final bool selectMode; // true ise bir yöntem seçip geri döndürür
  const OdemeYontemleriSayfasi({super.key, this.selectMode = false});

  @override
  State<OdemeYontemleriSayfasi> createState() => _OdemeYontemleriSayfasiState();
}

class _OdemeYontemleriSayfasiState extends State<OdemeYontemleriSayfasi> {
  List<OdemeYontemi> paymentMethods = [
    OdemeYontemi(
      id: '1',
      type: 'card',
      name: 'Visa Kart',
      number: '**** **** **** 1234',
      expiryDate: '12/25',
      isDefault: true,
    ),
    OdemeYontemi(
      id: '2',
      type: 'card',
      name: 'Mastercard',
      number: '**** **** **** 5678',
      expiryDate: '08/26',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ödeme Yöntemleri'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.grey[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (paymentMethods.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz ödeme yöntemi eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk ödeme yönteminizi ekleyerek başlayın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods[index];
                      return InkWell(
                        onTap: widget.selectMode
                            ? () => Navigator.pop(context, method)
                            : null,
                        child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                          child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: method.isDefault 
                                          ? Colors.green[100] 
                                          : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      method.isDefault ? 'Varsayılan' : 'Aktif',
                                      style: TextStyle(
                                        color: method.isDefault 
                                            ? Colors.green[700] 
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (widget.selectMode)
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(context, method),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Seç'),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editPaymentMethod(method);
                                      } else if (value == 'delete') {
                                        _deletePaymentMethod(method);
                                      } else if (value == 'default') {
                                        _setAsDefault(method);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16),
                                            SizedBox(width: 8),
                                            Text('Düzenle'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'default',
                                        child: Row(
                                          children: [
                                            Icon(Icons.star, size: 16),
                                            SizedBox(width: 8),
                                            Text('Varsayılan Yap'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Sil', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getCardColor(method.type),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCardIcon(method.type),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          method.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          method.number,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Son kullanma: ${method.expiryDate}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPaymentMethod,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ödeme Yöntemi'),
      ),
    );
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'card':
        return Colors.blue[600]!;
      case 'bank':
        return Colors.green[600]!;
      case 'digital':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getCardIcon(String type) {
    switch (type) {
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'digital':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  void _addNewPaymentMethod() {
    _showPaymentMethodDialog();
  }

  void _editPaymentMethod(OdemeYontemi method) {
    _showPaymentMethodDialog(method: method);
  }

  void _deletePaymentMethod(OdemeYontemi method) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ödeme Yöntemini Sil'),
          content: const Text('Bu ödeme yöntemini silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  paymentMethods.removeWhere((m) => m.id == method.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ödeme yöntemi silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _setAsDefault(OdemeYontemi method) {
    setState(() {
      for (var m in paymentMethods) {
        m = OdemeYontemi(
          id: m.id,
          type: m.type,
          name: m.name,
          number: m.number,
          expiryDate: m.expiryDate,
          isDefault: m.id == method.id,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Varsayılan ödeme yöntemi güncellendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPaymentMethodDialog({OdemeYontemi? method}) {
    final typeController = TextEditingController(text: method?.type ?? 'card');
    final nameController = TextEditingController(text: method?.name ?? '');
    final numberController = TextEditingController(text: method?.number ?? '');
    final expiryController = TextEditingController(text: method?.expiryDate ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(method == null ? 'Yeni Ödeme Yöntemi' : 'Ödeme Yöntemini Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'card', child: Text('Kredi/Banka Kartı')),
                    DropdownMenuItem(value: 'bank', child: Text('Banka Havalesi')),
                    DropdownMenuItem(value: 'digital', child: Text('Dijital Cüzdan')),
                  ],
                  onChanged: (value) {
                    typeController.text = value ?? 'card';
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Kart Sahibi / Yöntem Adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Kart Numarası / Hesap Bilgisi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: expiryController,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Son Kullanma Tarihi (MM/YY)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    numberController.text.isNotEmpty) {
                  
                  final newMethod = OdemeYontemi(
                    id: method?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    type: typeController.text,
                    name: nameController.text,
                    number: numberController.text,
                    expiryDate: expiryController.text,
                    isDefault: method?.isDefault ?? paymentMethods.isEmpty,
                  );

                  setState(() {
                    if (method != null) {
                      final index = paymentMethods.indexWhere((m) => m.id == method.id);
                      if (index != -1) {
                        paymentMethods[index] = newMethod;
                      }
                    } else {
                      paymentMethods.add(newMethod);
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(method == null ? 'Ödeme yöntemi eklendi' : 'Ödeme yöntemi güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen tüm alanları doldurun'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(method == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      },
    );
  }
}
