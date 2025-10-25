import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/review_service.dart';
// import '../services/storage_service.dart';
import 'star_rating.dart';

class AdvancedReviewForm extends StatefulWidget {
  final String productId;
  final VoidCallback onReviewAdded;
  final dynamic existingReview; // Düzenleme için

  const AdvancedReviewForm({
    super.key,
    required this.productId,
    required this.onReviewAdded,
    this.existingReview,
  });

  @override
  State<AdvancedReviewForm> createState() => _AdvancedReviewFormState();
}

class _AdvancedReviewFormState extends State<AdvancedReviewForm> {
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  List<String> _imageUrls = [];
  bool _hasPurchased = false;
  bool _checkingPurchase = true;

  @override
  void initState() {
    super.initState();
    _checkPurchaseStatus();
    if (widget.existingReview != null) {
      _selectedRating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
      _imageUrls = List.from(widget.existingReview!.imageUrls);
    }
  }

  Future<void> _checkPurchaseStatus() async {
    try {
      final hasPurchased = await ReviewService.hasUserPurchasedProduct(
        widget.productId,
        // Firebase Auth'dan user ID alınacak
        'current_user_id', // Bu gerçek user ID ile değiştirilecek
      );
      setState(() {
        _hasPurchased = hasPurchased;
        _checkingPurchase = false;
      });
    } catch (e) {
      setState(() {
        _hasPurchased = false;
        _checkingPurchase = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    try {
      // final storageService = StorageService();
      final List<String> urls = [];
      
      // Placeholder for image upload
      for (int i = 0; i < _selectedImages.length; i++) {
        // final url = await storageService.uploadReviewImage(
        //   widget.productId,
        //   _selectedImages[i],
        // );
        urls.add('placeholder_url_${DateTime.now().millisecondsSinceEpoch}_$i');
      }
      
      setState(() {
        _imageUrls.addAll(urls);
        _selectedImages.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraflar yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir puan verin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yorumunuzu yazın'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorumunuz en az 10 karakter olmalı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Fotoğrafları yükle
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      if (widget.existingReview != null) {
        // Yorum düzenleme
        await ReviewService.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          imageUrls: _imageUrls,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Yeni yorum ekleme
        await ReviewService.addReview(
          productId: widget.productId,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
          imageUrls: _imageUrls,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz başarıyla eklendi! Admin onayı bekliyor.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onReviewAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum işlenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    if (_checkingPurchase) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPurchased) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_cart, color: Colors.orange[600], size: 48),
            const SizedBox(height: 12),
            Text(
              'Yorum Yapabilmek İçin Ürünü Satın Almalısınız',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ürünü satın aldıktan sonra yorum yapabilirsiniz.',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.orange[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
              Icon(
                widget.existingReview != null ? Icons.edit : Icons.add_comment,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.existingReview != null ? 'Yorumu Düzenle' : 'Yorum Yap',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Puan seçimi
          Text(
            'Puanınız:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          StarRating(
            rating: _selectedRating.toDouble(),
            size: isSmallScreen ? 24 : 28,
            onRatingChanged: (rating) {
              setState(() => _selectedRating = rating.round());
            },
          ),
          const SizedBox(height: 16),
          
          // Yorum metni
          Text(
            'Yorumunuz:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Ürün hakkında düşüncelerinizi paylaşın...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fotoğraf ekleme
          Text(
            'Fotoğraflar (İsteğe bağlı):',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          
          // Fotoğraf seçme butonu
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo, size: 18),
            label: const Text('Fotoğraf Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Seçilen fotoğraflar
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Seçilen Fotoğraflar:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Yüklenen fotoğraflar
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Yüklenen Fotoğraflar:',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrls[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Gönder butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      widget.existingReview != null ? Icons.edit : Icons.send,
                      size: 18,
                    ),
              label: Text(
                _isSubmitting 
                    ? 'İşleniyor...' 
                    : widget.existingReview != null 
                        ? 'Yorumu Güncelle' 
                        : 'Yorumu Gönder',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bilgi metni
          Text(
            widget.existingReview != null 
                ? 'Yorumunuz güncellendiğinde admin onayı bekleyecektir.'
                : 'Yorumunuz admin onayından sonra yayınlanacaktır.',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
