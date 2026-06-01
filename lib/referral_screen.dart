import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  String _error = '';
  String _referralCode = '------';
  int _points = 0;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadReferralHistory();
    _loadReferralData();
  }

  String _makeCode(String uid) {
    final clean = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length >= 6) return clean.substring(0, 6);
    return clean.padRight(6, 'X');
  }

  Future<void> _loadReferralData() async {
    final uid = _uid;

    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Silakan login terlebih dahulu';
      });
      return;
    }

    try {
      final userRef = _db.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};

      String code = (data['referralCode'] ?? '').toString();

      if (code.isEmpty) {
        code = _makeCode(uid);
        await userRef.set({'referralCode': code}, SetOptions(merge: true));
      }

      if (!mounted) return;

      setState(() {
        _referralCode = code;
        _points = _toInt(data['totalPoints']);
        _loading = false;
        _error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat data referral';
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadReferralHistory() async {
    final uid = _uid;
    if (uid == null) return [];

    try {
      final snap = await _db
          .collection('referral_history')
          .where('referrerId', isEqualTo: uid)
          .get();

      final histories = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'refereeId': data['refereeId'],
          'pointsAwarded': data['pointsAwarded'],
          'createdAt': data['createdAt'],
        };
      }).toList();

      histories.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        return (bTime?.millisecondsSinceEpoch ?? 0)
            .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
      });

      return histories;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _historyFuture = _loadReferralHistory();
    });
    await _loadReferralData();
  }

  String _shareMessage() {
    return 'Hei! Pakai kode referral $_referralCode di app Kopiku Mana dan kita berdua dapat +15 poin gratis!';
  }

  Future<void> _copyCode() async {
    try {
      await Clipboard.setData(ClipboardData(text: _referralCode));
      if (!mounted) return;
      _showSnack('Kode referral disalin!', AppColors.primary);
    } catch (e) {
      if (!mounted) return;
      _showCopyFallbackDialog(
        title: 'Salin Kode Referral',
        text: _referralCode,
      );
    }
  }

  Future<void> _shareCode() async {
    final message = _shareMessage();

    try {
      final box = context.findRenderObject() as RenderBox?;

      await Share.share(
        message,
        subject: 'Kode Referral Kopiku Mana',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (!mounted) return;

      try {
        await Clipboard.setData(ClipboardData(text: message));
        if (!mounted) return;
        _showSnack('Pesan referral disalin!', AppColors.primary);
      } catch (_) {
        if (!mounted) return;
        _showCopyFallbackDialog(
          title: 'Bagikan Kode Referral',
          text: message,
        );
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showCopyFallbackDialog({
    required String title,
    required String text,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: SelectableText(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFF424242),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: _roundedReferralAppBar(),
      body: _body(),
    );
  }

  PreferredSizeWidget _roundedReferralAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                'Referral',
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

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _invitePanel(),
            const SizedBox(height: 24),
            Text('Riwayat Referral', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _historySection(),
          ],
        ),
      ),
    );
  }

  Widget _invitePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajak Teman',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Teman daftar pakai kodemu, kalian berdua dapat +15 poin.',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9DA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'KODE REFERRALMU',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withOpacity(0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _referralCode,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Salin',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Bagikan',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Poin kamu saat ini',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                ),
                Text(
                  '$_points poin',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historySection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(radius: 14),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final histories = snapshot.data ?? [];

        if (histories.isEmpty) {
          return _historyPlaceholder();
        }

        return Column(
          children: histories.map((item) {
            final createdAt = item['createdAt'] as Timestamp?;
            final date = createdAt?.toDate();
            final points = _toInt(item['pointsAwarded']);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(radius: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teman menggunakan kodemu',
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        ),
                        Text(
                          date == null
                              ? 'Baru saja'
                              : '${date.day}/${date.month}/${date.year}',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$points poin',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.statusActive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _historyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 14),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            color: AppColors.disabled,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada teman yang pakai kodemu.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return 0;
  }
}
