import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'cafe_model.dart';
import 'wishlist_service.dart';
import 'main_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Stream<List<String>> get _wishlistIdsStream {
    if (_uid == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return [];
      final data = snap.data();
      final list = data?['wishlist'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    });
  }

  // Stream data user untuk isPremium
  Stream<Map<String, dynamic>> get _userDataStream {
    if (_uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  Future<List<CafeModel>> _fetchCafes(List<String> ids) async {
    if (ids.isEmpty) return [];
    final cafes = <CafeModel>[];
    for (final id in ids) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('cafes').doc(id).get();
        if (doc.exists) {
          cafes.add(CafeModel.fromMap(doc.data()!, doc.id));
        }
      } catch (_) {}
    }
    return cafes;
  }

  Future<void> _removeFromWishlist(CafeModel cafe) async {
    await WishlistService.removeFromWishlist(cafe.cafeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cafe.name} dihapus dari wishlist'),
          backgroundColor: const Color(0xFF757575),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Cek apakah premium masih berlaku
  bool _isStillPremium(Map<String, dynamic> userData) {
    final isPremium = userData['isPremium'] as bool? ?? false;
    final premiumExpiry = userData['premiumExpiry'] as String?;
    if (!isPremium || premiumExpiry == null) return false;
    final expiryDate = DateTime.tryParse(premiumExpiry);
    if (expiryDate == null) return false;
    return expiryDate.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _userDataStream,
          builder: (context, userSnap) {
            final userData = userSnap.data ?? {};
            final isPremium = _isStillPremium(userData);
            final wishlistIds = (userData['wishlist'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];

            return FutureBuilder<List<CafeModel>>(
              future: _fetchCafes(wishlistIds),
              builder: (context, cafesSnapshot) {
                final isLoading = userSnap.connectionState ==
                        ConnectionState.waiting ||
                    cafesSnapshot.connectionState == ConnectionState.waiting;
                final cafes = cafesSnapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wishlist',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                isPremium
                                    ? 'Unlimited cafe tersimpan'
                                    : '${wishlistIds.length}/${WishlistService.maxFree} cafe tersimpan',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (!isPremium)
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/points-premium'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Limit bar (hanya untuk non-premium)
                    if (!isPremium)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: wishlistIds.length /
                                    WishlistService.maxFree,
                                backgroundColor: const Color(0xFFE0E0E0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  wishlistIds.length >= WishlistService.maxFree
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (wishlistIds.length >= WishlistService.maxFree)
                              Text(
                                'Limit tercapai! Upgrade Premium untuk wishlist unlimited.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary))
                          : cafes.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  itemCount: cafes.length,
                                  itemBuilder: (_, i) =>
                                      _buildWishlistItem(cafes[i]),
                                ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wishlist masih kosong',
            style: AppTextStyles.headingSmall
                .copyWith(color: const Color(0xFF212121)),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan cafe favoritmu\nagar mudah ditemukan lagi',
            style: AppTextStyles.bodyMedium
                .copyWith(color: const Color(0xFF9E9E9E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final mainScreen =
                    context.findAncestorStateOfType<MainScreenState>();
                mainScreen?.setTab(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Eksplor Cafe',
                  style: AppTextStyles.button.copyWith(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(CafeModel cafe) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty
                    ? Image.network(
                        cafe.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cafe.name,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${cafe.district}, ${cafe.city}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC107), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        cafe.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cafe.priceDisplay,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeFromWishlist(cafe),
              icon: const Icon(
                Icons.favorite_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.accent,
      child: const Center(
        child: Icon(Icons.coffee_rounded, color: AppColors.primary, size: 28),
      ),
    );
  }
}
