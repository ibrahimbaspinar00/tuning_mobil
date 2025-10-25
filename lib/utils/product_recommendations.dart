import 'dart:math';
import '../model/product.dart';

/// Ürün önerileri utility sınıfı
class ProductRecommendations {
  // Mevcut tüm ürünler (demo ürünler kaldırıldı)
  static final List<Product> _allProducts = [
    Product(
      id: '1',
      name: 'Premium Araç Temizlik Bezi',
      description: 'Yüksek kaliteli mikrofiber araç temizlik bezi. Çizik bırakmaz ve su emme kapasitesi yüksek.',
      price: 25.99,
      imageUrl: 'assets/images/placeholder.txt',
      category: 'Araç Temizlik',
      stock: 50,
      quantity: 1,
    ),
    Product(
      id: '2',
      name: 'Araç İçi Organizer',
      description: 'Araç konsolu için pratik organizer. Telefon, anahtar ve küçük eşyalar için bölmeler.',
      price: 35.50,
      imageUrl: 'assets/images/placeholder.txt',
      category: 'Organizatör',
      stock: 30,
      quantity: 1,
    ),
    Product(
      id: '3',
      name: 'Araç Kokusu - Vanilya',
      description: 'Doğal vanilya kokulu araç kokusu. Uzun süreli etkili ve hoş koku.',
      price: 32.99,
      imageUrl: 'assets/images/placeholder.txt',
      category: 'Koku',
      stock: 25,
      quantity: 1,
    ),
    Product(
      id: '4',
      name: 'Araç Kokusu - Lavanta',
      description: 'Rahatlatıcı lavanta kokulu araç kokusu. Stres azaltıcı etkisi.',
      price: 28.75,
      imageUrl: 'assets/images/placeholder.txt',
      category: 'Koku',
      stock: 20,
      quantity: 1,
    ),
    Product(
      id: '5',
      name: 'Telefon Tutucu - Manyetik',
      description: 'Güçlü manyetik telefon tutucu. Hızlı montaj ve güvenli tutma.',
      price: 45.00,
      imageUrl: 'assets/images/placeholder.txt',
      category: 'Telefon Aksesuar',
      stock: 100,
      quantity: 1,
    ),
  ];

  /// Rastgele ürün önerileri al
  static List<Product> getRandomRecommendations({int count = 3}) {
    // Ürünleri rastgele karıştır
    final shuffledProducts = List<Product>.from(_allProducts);
    shuffledProducts.shuffle(Random());
    
    // İstenen sayıda ürün döndür
    return shuffledProducts.take(count).toList();
  }

  /// Belirli ürünleri hariç tutarak rastgele öneriler al
  static List<Product> getRandomRecommendationsExcluding(
    List<Product> excludeProducts, 
    {int count = 3}
  ) {
    // Hariç tutulacak ürün isimlerini al
    final excludeNames = excludeProducts.map((p) => p.name).toSet();
    
    // Hariç tutulacak ürünleri filtrele
    final availableProducts = _allProducts
        .where((product) => !excludeNames.contains(product.name))
        .toList();
    
    // Eğer yeterli ürün yoksa tüm ürünleri kullan
    final productsToUse = availableProducts.isNotEmpty 
        ? availableProducts 
        : _allProducts;
    
    // Rastgele karıştır
    productsToUse.shuffle(Random());
    
    // İstenen sayıda ürün döndür
    return productsToUse.take(count).toList();
  }

  /// Tüm ürünleri al
  static List<Product> getAllProducts() {
    return List<Product>.from(_allProducts);
  }
}
