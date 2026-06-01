import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<_PointHistoryData> _historyFuture;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadData();
  }

  Future<_PointHistoryData> _loadData() async {
    final uid = _uid;
    if (uid == null) {
      return const _PointHistoryData(pointItems: [], pendingTopups: []);
    }

    final pointSnap = await _db
        .collection('point_history')
        .where('userId', isEqualTo: uid)
        .get();

    final pointItems = pointSnap.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();

    pointItems.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0)
          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });

    final topupSnap = await _db
        .collection('topup_transactions')
        .where('userId', isEqualTo: uid)
        .get();

    final pendingTopups = topupSnap.docs
        .map((doc) {
          return {
            ...doc.data(),
            'id': doc.id,
          };
        })
        .where((item) => (item['status'] ?? '').toString() == 'pending')
        .toList();

    pendingTopups.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      return (bTime?.millisecondsSinceEpoch ?? 0)
          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
    });

    return _PointHistoryData(
      pointItems: pointItems,
      pendingTopups: pendingTopups,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = _loadData();
    });
    await _historyFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: _roundedAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<_PointHistoryData>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final data = snapshot.data ??
                const _PointHistoryData(pointItems: [], pendingTopups: []);
            final pointItems = data.pointItems;
            final pendingTopups = data.pendingTopups;

            if (pointItems.isEmpty && pendingTopups.isEmpty) {
              return _emptyState();
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                if (pendingTopups.isNotEmpty) ...[
                  _sectionLabel('Top Up Pending'),
                  const SizedBox(height: 10),
                  ...pendingTopups.map(_pendingTopupCard),
                  const SizedBox(height: 20),
                ],
                if (pointItems.isNotEmpty) ...[
                  _sectionLabel('Riwayat Poin'),
                  const SizedBox(height: 10),
                  ...pointItems.map(_pointCard),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _roundedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
                'Riwayat Poin',
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

  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: AppTextStyles.headingSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pendingTopupCard(Map<String, dynamic> data) {
    final orderId = (data['orderId'] ?? data['id'] ?? '-').toString();
    final method = (data['paymentMethod'] ?? 'Midtrans Sandbox').toString();
    final points = _toInt(data['points']);
    final price = _toInt(data['price']);
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: const Color(0xFFFFD36A),
        shadowAlpha: 0.06,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFF9A6A00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pembayaran',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$method • ${_formatRupiah(price)} • ${_formatDate(createdAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderId,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+$points',
            style: AppTextStyles.labelLarge.copyWith(
              color: const Color(0xFF9A6A00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointCard(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final description =
        (data['description'] ?? _labelFromType(type)).toString();
    final amount = _toInt(data['amount']);
    final price = _toInt(data['price']);
    final createdAt = data['createdAt'] as Timestamp?;

    final isPositive = amount >= 0;
    final color = isPositive ? AppColors.statusActive : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFromType(type, isPositive),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price > 0
                      ? '${_labelFromType(type)} • ${_formatRupiah(price)} • ${_formatDate(createdAt)}'
                      : '${_labelFromType(type)} • ${_formatDate(createdAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isPositive ? '+' : ''}$amount',
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
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
          Icons.receipt_long_outlined,
          color: AppColors.disabled,
          size: 54,
        ),
        const SizedBox(height: 14),
        Text(
          'Belum Ada Riwayat Poin',
          style: AppTextStyles.headingSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Top up, referral, dan pemakaian premium akan muncul di sini.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _iconFromType(String type, bool isPositive) {
    switch (type) {
      case 'topup':
        return Icons.add_card_rounded;
      case 'redeem':
        return Icons.workspace_premium_rounded;
      case 'referral':
        return Icons.people_alt_rounded;
      case 'review':
        return Icons.rate_review_rounded;
      default:
        return isPositive
            ? Icons.add_circle_outline_rounded
            : Icons.remove_circle_outline_rounded;
    }
  }

  String _labelFromType(String type) {
    switch (type) {
      case 'topup':
        return 'Top Up';
      case 'redeem':
        return 'Redeem';
      case 'referral':
        return 'Referral';
      case 'review':
        return 'Ulasan';
      default:
        return 'Transaksi';
    }
  }

  BoxDecoration _cardDecoration({
    Color borderColor = const Color(0xFFEDE7E1),
    double shadowAlpha = 0.07,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
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

  String _formatRupiah(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp$buffer';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }
}

class _PointHistoryData {
  final List<Map<String, dynamic>> pointItems;
  final List<Map<String, dynamic>> pendingTopups;

  const _PointHistoryData({
    required this.pointItems,
    required this.pendingTopups,
  });
}
