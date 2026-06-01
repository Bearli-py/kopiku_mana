import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedPlan = 0;
  bool _isLoading = false;

  String? get _uid => _auth.currentUser?.uid;

  final List<Map<String, dynamic>> _plans = [
    {
      'label': '7 Hari',
      'days': 7,
      'points': 100,
      'desc': 'Cocok untuk coba fitur Premium',
      'badge': null,
    },
    {
      'label': '30 Hari',
      'days': 30,
      'points': 350,
      'desc': 'Lebih hemat untuk eksplor rutin',
      'badge': 'TERPOPULER',
    },
  ];

  final List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.lock_open_rounded,
      'title': 'Akses Hidden Gems',
      'desc': 'Lihat cafe tersembunyi yang dikurasi khusus.',
    },
    {
      'icon': Icons.favorite_rounded,
      'title': 'Wishlist Unlimited',
      'desc': 'Simpan cafe favorit tanpa batas maksimal.',
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Filter Advanced',
      'desc': 'Temukan cafe berdasarkan suasana dan fasilitas.',
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'title': 'Badge Premium',
      'desc': 'Tampilkan status Premium Member di profilmu.',
    },
  ];

  Future<void> _activatePremium(DateTime? currentExpiry) async {
    if (_uid == null) return;

    setState(() => _isLoading = true);

    try {
      final plan = _plans[_selectedPlan];
      final requiredPoints = plan['points'] as int;
      final days = plan['days'] as int;

      final doc = await _db.collection('users').doc(_uid).get();
      final data = doc.data() ?? {};
      final currentPoints = data['totalPoints'] as int? ?? 0;

      if (currentPoints < requiredPoints) {
        setState(() => _isLoading = false);
        _showInsufficientDialog(currentPoints, requiredPoints);
        return;
      }

      final now = DateTime.now();
      final baseDate = currentExpiry != null && currentExpiry.isAfter(now)
          ? currentExpiry
          : now;
      final expiry = baseDate.add(Duration(days: days));

      await _db.collection('users').doc(_uid).set({
        'isPremium': true,
        'premiumExpiry': expiry.toIso8601String(),
        'totalPoints': FieldValue.increment(-requiredPoints),
      }, SetOptions(merge: true));

      await _db.collection('point_history').add({
        'userId': _uid,
        'type': 'redeem',
        'amount': -requiredPoints,
        'description': 'Aktivasi Premium ${plan['label']}',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSuccessDialog(plan['label'] as String, expiry);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showSnack('Gagal aktivasi, coba lagi', AppColors.error);
    }
  }

  void _showInsufficientDialog(int current, int required) {
    final shortage = required - current;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
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
                child: const Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text('Poin Belum Cukup', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Kamu punya $current poin dan butuh $required poin.\nMasih kurang $shortage poin.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              _tipItem(
                icon: Icons.add_card_rounded,
                title: 'Top Up Poin',
                subtitle: 'Tambah poin secara cepat melalui halaman Top Up.',
              ),
              _tipItem(
                icon: Icons.people_alt_rounded,
                title: 'Bagikan Referral',
                subtitle: 'Ajak teman daftar dan dapat +15 poin.',
              ),
              _tipItem(
                icon: Icons.rate_review_rounded,
                title: 'Tulis Ulasan',
                subtitle: 'Dapatkan poin dari ulasan cafe yang kamu kunjungi.',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.referral);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Referral',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.topup);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Top Up',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String planLabel, DateTime expiry) {
    final expiryStr = '${expiry.day}/${expiry.month}/${expiry.year}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
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
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text('Premium Aktif!', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Premium $planLabel berhasil diaktifkan.\nBerlaku hingga $expiryStr',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Nikmati Premium',
                    style: AppTextStyles.button.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _uid != null
            ? _db.collection('users').doc(_uid).snapshots()
            : const Stream.empty(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>? ?? {};
          final currentPoints = data['totalPoints'] as int? ?? 0;
          final isPremium = data['isPremium'] as bool? ?? false;
          final premiumExpiry = data['premiumExpiry'] as String?;

          DateTime? expiryDate;
          if (premiumExpiry != null) {
            expiryDate = DateTime.tryParse(premiumExpiry);
          }

          final isStillPremium = isPremium &&
              expiryDate != null &&
              expiryDate.isAfter(DateTime.now());

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _header(
                  currentPoints: currentPoints,
                  isStillPremium: isStillPremium,
                  expiryDate: expiryDate,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              _sectionTitle('Keuntungan Premium'),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _benefitList()),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              _sectionTitle(
                  isStillPremium ? 'Perpanjang Paket' : 'Pilih Paket'),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _planList(currentPoints)),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _activatePremium(expiryDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFBDBDBD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '${isStillPremium ? 'Perpanjang' : 'Aktifkan'} ${_plans[_selectedPlan]['label']} - ${_plans[_selectedPlan]['points']} Poin',
                              style:
                                  AppTextStyles.button.copyWith(fontSize: 14),
                            ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _header({
    required int currentPoints,
    required bool isStillPremium,
    DateTime? expiryDate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Premium', style: AppTextStyles.headingSmall),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF8),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFEDE7E1), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStillPremium ? 'Status Premium' : 'Kopiku Mana Premium',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isStillPremium ? 'Premium Aktif' : 'Buka fitur eksklusif',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isStillPremium && expiryDate != null
                          ? 'Berlaku hingga ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}'
                          : 'Akses Hidden Gems, wishlist unlimited, dan filter advanced.',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E9DA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Saldo poin',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF757575),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$currentPoints poin',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(title, style: AppTextStyles.headingSmall),
      ),
    );
  }

  Widget _benefitList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _benefits
            .map(
              (b) => _benefitItem(
                icon: b['icon'] as IconData,
                title: b['title'] as String,
                desc: b['desc'] as String,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _benefitItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF212121),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 19,
          ),
        ],
      ),
    );
  }

  Widget _planList(int currentPoints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_plans.length, (i) {
          final plan = _plans[i];
          final isSelected = _selectedPlan == i;
          final canAfford = currentPoints >= (plan['points'] as int);

          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFEDE7E1),
                  width: isSelected ? 1.4 : 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.045),
                    blurRadius: isSelected ? 14 : 8,
                    offset: Offset(0, isSelected ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFEDE7E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              plan['label'] as String,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (plan['badge'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  plan['badge'] as String,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan['desc'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                        if (!canAfford) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Poin belum cukup',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${plan['points']} poin',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFBDBDBD),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEDE7E1), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
