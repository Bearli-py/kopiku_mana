import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _notifyReview = true;
  bool _notifyPromo = false;
  bool _notifyRecommendation = true;
  bool _savingNotif = false;

  String? get _uid => _auth.currentUser?.uid;

  Stream<DocumentSnapshot> get _userStream {
    if (_uid == null) return const Stream.empty();
    return _db.collection('users').doc(_uid).snapshots();
  }

  DateTime? _parseExpiry(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool _isPremiumActive(Map<String, dynamic> data) {
    final isPremium = data['isPremium'] as bool? ?? false;
    if (!isPremium) return false;
    final expiry = _parseExpiry(data['premiumExpiry']);
    return expiry != null && expiry.isAfter(DateTime.now());
  }

  String _premiumLabel(Map<String, dynamic> data) {
    if (!_isPremiumActive(data)) return 'Belum Premium';
    final expiry = _parseExpiry(data['premiumExpiry'])!;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return 'Aktif sampai ${expiry.day} ${months[expiry.month - 1]} ${expiry.year}';
  }

  void _syncNotificationPrefs(Map<String, dynamic> data) {
    final notifyReview = data['notifyReview'] as bool? ?? true;
    final notifyPromo = data['notifyPromo'] as bool? ?? false;
    final notifyRecommendation = data['notifyRecommendation'] as bool? ?? true;

    if (_notifyReview == notifyReview &&
        _notifyPromo == notifyPromo &&
        _notifyRecommendation == notifyRecommendation) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _notifyReview = notifyReview;
        _notifyPromo = notifyPromo;
        _notifyRecommendation = notifyRecommendation;
      });
    });
  }

  Future<void> _updateNotificationPref(String key, bool value) async {
    final uid = _uid;
    if (uid == null) return;

    setState(() => _savingNotif = true);

    try {
      await _db.collection('users').doc(uid).set({
        key: value,
        'notificationPrefsUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal menyimpan pengaturan'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingNotif = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Keluar', style: AppTextStyles.headingSmall),
        content: Text(
          'Yakin mau keluar dari akun ini?',
          style:
              AppTextStyles.bodyMedium.copyWith(color: const Color(0xFF757575)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal',
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF9E9E9E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Keluar',
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 20, 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  'Pengaturan',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _userStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                _syncNotificationPrefs(data);

                final name = data['name'] as String? ??
                    authUser?.displayName ??
                    authUser?.email?.split('@').first ??
                    'Pengguna';
                final email =
                    data['email'] as String? ?? authUser?.email ?? '-';
                final totalPoints = data['totalPoints'] as int? ?? 0;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _section('Akun'),
                    _tile(
                      icon: Icons.person_outline_rounded,
                      title: 'Nama',
                      subtitle: name,
                      onTap: () => Navigator.pop(context),
                    ),
                    _tile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: email,
                    ),
                    _tile(
                      icon: Icons.stars_rounded,
                      title: 'Poin',
                      subtitle: '$totalPoints poin',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.topup),
                    ),
                    const SizedBox(height: 20),
                    _section('Premium'),
                    _tile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Status Premium',
                      subtitle: _premiumLabel(data),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.premium),
                    ),
                    const SizedBox(height: 20),
                    _section('Notifikasi'),
                    _switchTile(
                      title: 'Review & balasan',
                      subtitle: 'Kabar review kamu disetujui',
                      value: _notifyReview,
                      onChanged: _savingNotif
                          ? null
                          : (v) {
                              setState(() => _notifyReview = v);
                              _updateNotificationPref('notifyReview', v);
                            },
                    ),
                    _switchTile(
                      title: 'Promo & tips',
                      subtitle: 'Info premium dan poin',
                      value: _notifyPromo,
                      onChanged: _savingNotif
                          ? null
                          : (v) {
                              setState(() => _notifyPromo = v);
                              _updateNotificationPref('notifyPromo', v);
                            },
                    ),
                    _switchTile(
                      title: 'Rekomendasi cafe',
                      subtitle: 'Saran cafe baru di sekitar Tapal Kuda',
                      value: _notifyRecommendation,
                      onChanged: _savingNotif
                          ? null
                          : (v) {
                              setState(() => _notifyRecommendation = v);
                              _updateNotificationPref(
                                  'notifyRecommendation', v);
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        'Preferensi disimpan. Notifikasi push menyusul di versi berikutnya.',
                        style: AppTextStyles.caption
                            .copyWith(color: const Color(0xFF9E9E9E)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section('Aplikasi'),
                    _tile(
                      icon: Icons.help_outline_rounded,
                      title: 'Bantuan',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                    ),
                    _tile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Kopiku Mana',
                      subtitle: 'Versi 1.0.0',
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Keluar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF9E9E9E)),
              )
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD))
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        activeColor: AppColors.primary,
        title: Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: const Color(0xFF9E9E9E)),
        ),
      ),
    );
  }
}
