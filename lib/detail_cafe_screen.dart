import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'cafe_model.dart';
import 'wishlist_service.dart';

class DetailCafeScreen extends StatefulWidget {
  final CafeModel cafe;
  const DetailCafeScreen({super.key, required this.cafe});

  @override
  State<DetailCafeScreen> createState() => _DetailCafeScreenState();
}

class _DetailCafeScreenState extends State<DetailCafeScreen> {
  int _currentPhoto = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _reviews = [];
  bool _loadingReviews = true;

  bool _isWishlisted = false;
  bool _wishlistLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkWishlist();
    _checkPremium();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPremium() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final isPremium = data['isPremium'] as bool? ?? false;
      final premiumExpiry = data['premiumExpiry'] as String?;
      DateTime? expiryDate;
      if (premiumExpiry != null) {
        expiryDate = DateTime.tryParse(premiumExpiry);
      }
      final isStillPremium =
          isPremium && expiryDate != null && expiryDate.isAfter(DateTime.now());
      if (mounted) setState(() => _isPremium = isStillPremium);
    } catch (_) {}
  }

  Future<void> _checkWishlist() async {
    final result = await WishlistService.isWishlisted(widget.cafe.cafeId);
    if (mounted) setState(() => _isWishlisted = result);
  }

  Future<void> _toggleWishlist() async {
    if (_wishlistLoading) return;
    setState(() => _wishlistLoading = true);

    final result =
        await WishlistService.toggleWishlist(widget.cafe.cafeId, _isPremium);

    if (!mounted) return;
    setState(() => _wishlistLoading = false);

    if (result == 'added') {
      setState(() => _isWishlisted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${widget.cafe.name} ditambahkan ke wishlist!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result == 'removed') {
      setState(() => _isWishlisted = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite_border_rounded,
                  color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Dihapus dari wishlist'),
            ],
          ),
          backgroundColor: const Color(0xFF757575),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (result == 'limit') {
      _showLimitDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal, coba lagi'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showLimitDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Wishlist Penuh!', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Kamu sudah menyimpan 3 cafe (batas gratis).\nUpgrade Premium untuk wishlist unlimited!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: const Color(0xFF757575)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.pushNamed(context, AppRoutes.premium);
                  _checkPremium();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Upgrade Premium',
                    style: AppTextStyles.button.copyWith(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Nanti saja',
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF9E9E9E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadReviews() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('cafeId', isEqualTo: widget.cafe.cafeId)
          .where('isVerified', isEqualTo: true)
          .get();
      if (mounted) {
        setState(() {
          _reviews = snap.docs.map((d) => d.data()).toList();
          _loadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ReviewSheet(cafe: widget.cafe, onSubmitted: _loadReviews),
    );
  }

  bool get _hasPowerOutlet {
    final combined = [...widget.cafe.atmosphere, ...widget.cafe.category];
    return combined.any((v) =>
        v.toLowerCase() == 'study friendly' || v.toLowerCase() == 'nugas');
  }

  bool get _hasIndoor {
    final combined = [...widget.cafe.atmosphere, ...widget.cafe.category];
    return combined.any((v) => v.toLowerCase() == 'indoor');
  }

  @override
  Widget build(BuildContext context) {
    final cafe = widget.cafe;
    final photos = cafe.photos.where((p) => p.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero foto ──
                SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 300,
                          child: photos.isEmpty
                              ? Container(
                                  color: AppColors.accent,
                                  child: const Center(
                                    child: Icon(Icons.coffee_rounded,
                                        color: AppColors.primary, size: 64),
                                  ),
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: photos.length,
                                  onPageChanged: (i) =>
                                      setState(() => _currentPhoto = i),
                                  itemBuilder: (_, i) => Image.network(
                                    photos[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppColors.accent,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.accent,
                                      child: const Center(
                                        child: Icon(Icons.coffee_rounded,
                                            color: AppColors.primary, size: 64),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.3),
                                  ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: AppColors.primary, size: 16),
                          ),
                        ),
                      ),

                      // Wishlist button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        right: 16,
                        child: GestureDetector(
                          onTap: _toggleWishlist,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: _wishlistLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary),
                                  )
                                : Icon(
                                    _isWishlisted
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    color: _isWishlisted
                                        ? Colors.red
                                        : AppColors.primary,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),

                      if (photos.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              photos.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentPhoto == i ? 20 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _currentPhoto == i
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (photos.length > 1)
                        Positioned(
                          bottom: 14,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentPhoto + 1}/${photos.length}',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Konten ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Nama + status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(cafe.name,
                                style: AppTextStyles.headingLarge),
                          ),
                          const SizedBox(width: 12),
                          _statusBadge(cafe.status),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Rating + ulasan + harga
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            cafe.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cafe.totalReviews} ulasan',
                            style: AppTextStyles.caption
                                .copyWith(color: const Color(0xFF9E9E9E)),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFBDBDBD),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            cafe.priceDisplay,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Lokasi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 15, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cafe.address.isNotEmpty
                                  ? cafe.address
                                  : '${cafe.district}, ${cafe.city}',
                              style: AppTextStyles.caption
                                  .copyWith(color: const Color(0xFF757575)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 20),

                      // Fasilitas grid
                      Text('Fasilitas', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: [
                          _fasilitasGrid(
                              Icons.wifi_rounded, 'WiFi', cafe.hasWifi),
                          _fasilitasGrid(Icons.electrical_services_rounded,
                              'Stopkontak', _hasPowerOutlet),
                          _fasilitasGrid(
                              Icons.local_parking_rounded, 'Parkir', true),
                          _fasilitasGrid(
                              Icons.ac_unit_rounded, 'AC Indoor', _hasIndoor),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // Suasana
                      Text('Suasana', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...cafe.atmosphere.map((a) => _suasanaChip(a)),
                          ...cafe.category.map((c) => _suasanaChip(c)),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // Ulasan
                      Row(
                        children: [
                          Text('Ulasan', style: AppTextStyles.headingSmall),
                          const Spacer(),
                          GestureDetector(
                            onTap: _openReviewSheet,
                            child: Text(
                              '+ Tulis Ulasan',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _loadingReviews
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : _reviews.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F5F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.rate_review_outlined,
                                          color: AppColors.disabled, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Belum ada ulasan',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                                color: const Color(0xFF9E9E9E)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jadilah yang pertama mengulas cafe ini!',
                                        style: AppTextStyles.caption,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: _reviews
                                      .map((r) => _buildReviewItem(r))
                                      .toList(),
                                ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openReviewSheet,
            icon: const Icon(Icons.rate_review_outlined,
                color: Colors.white, size: 18),
            label: const Text('Tulis Ulasan & Dapat Poin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fasilitasGrid(IconData icon, String label, bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: available ? AppColors.accent : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: 18,
                color: available ? AppColors.primary : AppColors.disabled),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: available ? const Color(0xFF212121) : AppColors.disabled,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suasanaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF424242),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final List<dynamic> reviewPhotos = review['photos'] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review['userName'] ?? 'Pengguna',
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < (review['rating'] ?? 0)
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['text'] ?? '', style: AppTextStyles.bodySmall),
          if (reviewPhotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reviewPhotos.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      reviewPhotos[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.accent,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'aktif':
        color = AppColors.statusActive;
        label = '● Aktif';
        break;
      case 'tutup':
        color = AppColors.statusClosed;
        label = '● Tutup';
        break;
      default:
        color = AppColors.statusConfirm;
        label = '● Perlu Konfirmasi';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Review Sheet ──
class _ReviewSheet extends StatefulWidget {
  final CafeModel cafe;
  final VoidCallback onSubmitted;

  const _ReviewSheet({required this.cafe, required this.onSubmitted});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  int _rating = 0;
  bool _isLoading = false;
  String _error = '';
  List<File> _selectedImages = [];

  static const String _imgbbKey = '99a2b6d2c9cd97cf8cf369cb583a7e9b';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) {
      setState(() => _error = 'Maksimal 3 foto');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1080,
      );
      if (picked != null) {
        setState(() {
          _selectedImages.add(File(picked.path));
          _error = '';
        });
      }
    } catch (e) {
      setState(() => _error = 'Gagal memilih foto');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<String?> _uploadToImgbb(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbKey'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Pilih rating terlebih dahulu');
      return;
    }
    final text = _textController.text.trim();
    final sentences =
        text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    if (sentences < 3) {
      setState(() => _error = 'Ulasan minimal 3 kalimat');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Belum login');

      List<String> photoUrls = [];
      for (final file in _selectedImages) {
        final url = await _uploadToImgbb(file);
        if (url != null) photoUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('reviews').add({
        'cafeId': widget.cafe.cafeId,
        'userId': user.uid,
        'userName':
            user.displayName ?? user.email?.split('@').first ?? 'Pengguna',
        'rating': _rating,
        'text': text,
        'photos': photoUrls,
        'isDuplicate': false,
        'isVerified': true,
        'pointsAwarded': 20,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ulasan berhasil! +20 poin'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal mengirim ulasan, coba lagi';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Tulis Ulasan', style: AppTextStyles.headingSmall),
            const SizedBox(height: 4),
            Text(
              widget.cafe.name,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: const Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 20),
            Text('Rating', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.star_rounded,
                      size: 36,
                      color: i < _rating
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ulasan', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 5,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Tulis minimal 3 kalimat tentang cafe ini...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFFBDBDBD)),
                filled: true,
                fillColor: const Color(0xFFF8F5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Foto (opsional, maks. 3)', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_selectedImages.length < 3)
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F5F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.primary, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            'Tambah',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...List.generate(_selectedImages.length, (i) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[i]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Review valid → +20 poin otomatis',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Kirim Ulasan',
                        style: AppTextStyles.button.copyWith(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
