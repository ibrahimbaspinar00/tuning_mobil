import 'package:flutter/material.dart';

class Adres {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String district;
  final String postalCode;
  final bool isDefault;

  Adres({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    required this.district,
    required this.postalCode,
    this.isDefault = false,
  });
}

class AdresYonetimiSayfasi extends StatefulWidget {
  const AdresYonetimiSayfasi({super.key});

  @override
  State<AdresYonetimiSayfasi> createState() => _AdresYonetimiSayfasiState();
}

class _AdresYonetimiSayfasiState extends State<AdresYonetimiSayfasi> {
  List<Adres> addresses = [
    Adres(
      id: '1',
      title: 'Ev',
      fullName: 'Misafir Kullanıcı',
      phone: '+90 555 123 45 67',
      address: 'Atatürk Mahallesi, Cumhuriyet Caddesi No:123 Daire:5',
      city: 'İstanbul',
      district: 'Kadıköy',
      postalCode: '34710',
      isDefault: true,
    ),
    Adres(
      id: '2',
      title: 'İş',
      fullName: 'Misafir Kullanıcı',
      phone: '+90 555 123 45 67',
      address: 'Levent Mahallesi, Büyükdere Caddesi No:45',
      city: 'İstanbul',
      district: 'Beşiktaş',
      postalCode: '34330',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Adreslerim'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.grey[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (addresses.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz adres eklenmemiş',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk adresinizi ekleyerek başlayın',
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
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      return Container(
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
                                      color: address.isDefault 
                                          ? Colors.green[100] 
                                          : Colors.blue[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      address.isDefault ? 'Varsayılan' : address.title,
                                      style: TextStyle(
                                        color: address.isDefault 
                                            ? Colors.green[700] 
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editAddress(address);
                                      } else if (value == 'delete') {
                                        _deleteAddress(address);
                                      } else if (value == 'default') {
                                        _setAsDefault(address);
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
                              Text(
                                address.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.phone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.address,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.district}, ${address.city} ${address.postalCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
        onPressed: _addNewAddress,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Adres'),
      ),
    );
  }

  void _addNewAddress() {
    _showAddressDialog();
  }

  void _editAddress(Adres address) {
    _showAddressDialog(address: address);
  }

  void _deleteAddress(Adres address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adresi Sil'),
          content: const Text('Bu adresi silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  addresses.removeWhere((a) => a.id == address.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adres silindi'),
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

  void _setAsDefault(Adres address) {
    setState(() {
      for (var addr in addresses) {
        addr = Adres(
          id: addr.id,
          title: addr.title,
          fullName: addr.fullName,
          phone: addr.phone,
          address: addr.address,
          city: addr.city,
          district: addr.district,
          postalCode: addr.postalCode,
          isDefault: addr.id == address.id,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Varsayılan adres güncellendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddressDialog({Adres? address}) {
    final titleController = TextEditingController(text: address?.title ?? '');
    final fullNameController = TextEditingController(text: address?.fullName ?? '');
    final phoneController = TextEditingController(text: address?.phone ?? '');
    final addressController = TextEditingController(text: address?.address ?? '');
    final cityController = TextEditingController(text: address?.city ?? '');
    final districtController = TextEditingController(text: address?.district ?? '');
    final postalCodeController = TextEditingController(text: address?.postalCode ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(address == null ? 'Yeni Adres' : 'Adresi Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Adres Başlığı (Ev, İş, vb.)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adres',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'Şehir',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: districtController,
                        decoration: const InputDecoration(
                          labelText: 'İlçe',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Posta Kodu',
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
                if (titleController.text.isNotEmpty &&
                    fullNameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty &&
                    addressController.text.isNotEmpty) {
                  
                  final newAddress = Adres(
                    id: address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    fullName: fullNameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                    city: cityController.text,
                    district: districtController.text,
                    postalCode: postalCodeController.text,
                    isDefault: address?.isDefault ?? addresses.isEmpty,
                  );

                  setState(() {
                    if (address != null) {
                      final index = addresses.indexWhere((a) => a.id == address.id);
                      if (index != -1) {
                        addresses[index] = newAddress;
                      }
                    } else {
                      addresses.add(newAddress);
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(address == null ? 'Adres eklendi' : 'Adres güncellendi'),
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
              child: Text(address == null ? 'Ekle' : 'Güncelle'),
            ),
          ],
        );
      },
    );
  }
}
