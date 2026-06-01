import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<List<Map<String, dynamic>>> _reviewsFuture;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<List<Map<String, dynamic>>> _loadReviews() async {
    final uid = _uid;
    if (uid == null) return [];

    final snap =
        await _db.collection('reviews').where('userId', isEqualTo: uid).get();

    final items = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final data = doc.data();
      String cafeName = 'Cafe';

      final cafeId = data['cafeId']?.toString() ?? '';
      if (cafeId.isNotEmpty) {
        try {
          final cafeSnap = await _db.collection('cafes').doc(cafeId).get();
          cafeName = (cafeSnap.data()?['name'] ?? 'Cafe').toString();
        } catch (_) {}
      }

      items.add({
        ...data,
        'id': doc.id,
        'cafeName': cafeName,
      });
    }

    items.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0)
          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });

    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _reviewsFuture = _loadReviews();
    });
    await _reviewsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return _emptyState();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _reviewCard(reviews[index]),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Riwayat Ulasan',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> data) {
    final rating = _toInt(data['rating']);
    final text = (data['text'] ?? '').toString();
    final cafeName = (data['cafeName'] ?? 'Cafe').toString();
    final points = _toInt(data['pointsAwarded']);
    final isVerified = data['isVerified'] == true;
    final isDuplicate = data['isDuplicate'] == true;
    final createdAt = data['createdAt'] as Timestamp?;
    final photos = data['photos'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cafeName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusBadge(isVerified, isDuplicate),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB300),
                  size: 18,
                );
              }),
              const SizedBox(width: 8),
              Text(
                _formatDate(createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF424242),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (photos.isNotEmpty)
                _miniInfo(Icons.image_outlined, '${photos.length} foto'),
              if (photos.isNotEmpty) const SizedBox(width: 8),
              _miniInfo(Icons.monetization_on_outlined, '+$points poin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isVerified, bool isDuplicate) {
    Color color;
    String label;

    if (isDuplicate) {
      color = AppColors.error;
      label = 'Duplikat';
    } else if (isVerified) {
      color = AppColors.statusActive;
      label = 'Terverifikasi';
    } else {
      color = AppColors.warning;
      label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.rate_review_outlined,
          color: AppColors.disabled,
          size: 54,
        ),
        const SizedBox(height: 14),
        Text(
          'Belum Ada Ulasan',
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Ulasan yang kamu tulis akan muncul di sini.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE7E1), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    final d = timestamp.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }
}
