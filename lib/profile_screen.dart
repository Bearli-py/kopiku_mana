import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  static const String _imgbbKey = '99a2b6d2c9cd97cf8cf369cb583a7e9b';

  String _name = 'Pengguna';
  String _email = '';
  String? _photoUrl;
  String? _photoBase64;
  bool _uploadingPhoto = false;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  String? _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _normalizePhotoUrl(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim();

    if (uri.host == 'i.ibb.co.com' || uri.host == 'ibb.co.com') {
      return uri.replace(host: 'i.ibb.co').toString();
    }
    return uri.toString();
  }

  String? _extractUploadedPhotoUrl(Map<String, dynamic> uploadData) {
    final image = uploadData['image'];
    final thumb = uploadData['thumb'];

    return _normalizePhotoUrl(
      _firstNonEmpty([
        if (image is Map<String, dynamic>) image['url'],
        uploadData['display_url'],
        if (thumb is Map<String, dynamic>) thumb['url'],
        uploadData['url'],
      ]),
    );
  }

  ImageProvider? _profileImageProvider(String? photoUrl, String? photoBase64) {
    final base64Value = photoBase64?.trim();
    if (base64Value != null && base64Value.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Value));
      } catch (_) {
        // Fall back to the hosted image URL below.
      }
    }

    final url = _normalizePhotoUrl(photoUrl);
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  Future<void> _loadUser() async {
    var user = _auth.currentUser;
    final cachedUser = user;
    if (cachedUser != null && mounted) {
      setState(() {
        _name = cachedUser.displayName ??
            cachedUser.email?.split('@').first ??
            'Pengguna';
        _email = cachedUser.email ?? '';
        _photoUrl = _normalizePhotoUrl(cachedUser.photoURL);
      });
    }

    try {
      await user?.reload();
      user = _auth.currentUser;
    } catch (_) {
      user = _auth.currentUser;
    }

    if (user != null) {
      if (!mounted) return;
      final refreshedUser = user;
      setState(() {
        _name = refreshedUser.displayName ??
            refreshedUser.email?.split('@').first ??
            'Pengguna';
        _email = refreshedUser.email ?? '';
        _photoUrl = _normalizePhotoUrl(refreshedUser.photoURL);
      });

      try {
        final doc = await _db.collection('users').doc(refreshedUser.uid).get();
        final data = doc.data();
        if (!mounted || data == null) return;

        setState(() {
          _name = _firstNonEmpty([data['name'], _name]) ?? _name;
          _photoUrl = _normalizePhotoUrl(
            _firstNonEmpty([
              data['photoUrl'],
              data['photoURL'],
              data['avatarUrl'],
              _photoUrl,
            ]),
          );
          _photoBase64 = _firstNonEmpty([data['photoBase64'], _photoBase64]);
        });
      } catch (_) {
        return;
      }
    }
  }

  Stream<DocumentSnapshot> get _userStream {
    if (_uid == null) return const Stream.empty();
    return _db.collection('users').doc(_uid).snapshots();
  }

  Stream<int> get _reviewCountStream {
    if (_uid == null) return Stream.value(0);
    return _db
        .collection('reviews')
        .where('userId', isEqualTo: _uid)
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  DateTime? _parseExpiry(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Future<void> _pickAndUploadPhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Upload foto hanya tersedia di aplikasi Android'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 512,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      String? url;
      try {
        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbKey'),
          body: {'image': base64Image},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final uploadData = data['data'] as Map<String, dynamic>;
          url = _extractUploadedPhotoUrl(uploadData);
        }
      } catch (_) {
        url = null;
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User belum login');

      if (url != null) {
        await user.updatePhotoURL(url);
      }

      await _db.collection('users').doc(user.uid).set({
        if (url != null) ...{
          'photoUrl': url,
          'photoURL': url,
          'avatarUrl': url,
        },
        'photoBase64': base64Image,
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _photoUrl = url ?? _photoUrl;
        _photoBase64 = base64Image;
        _uploadingPhoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Foto profil berhasil diperbarui!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal upload foto, coba lagi'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar',
          style: AppTextStyles.headingSmall.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: Text(
            'Yakin mau keluar dari akun ini?',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              color: const Color(0xFF757575),
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text(
              'Batal',
              style: AppTextStyles.labelLarge.copyWith(
                color: const Color(0xFF9E9E9E),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text(
              'Keluar',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, userSnap) {
            final userData =
                userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final displayName =
                _firstNonEmpty([userData['name'], _name]) ?? _name;
            final photoUrl = _normalizePhotoUrl(
              _firstNonEmpty([
                userData['photoUrl'],
                userData['photoURL'],
                userData['avatarUrl'],
                _photoUrl,
              ]),
            );
            final photoBase64 =
                _firstNonEmpty([userData['photoBase64'], _photoBase64]);
            final profileImage = _profileImageProvider(photoUrl, photoBase64);
            final totalPoints = userData['totalPoints'] as int? ?? 0;
            final isPremium = userData['isPremium'] as bool? ?? false;
            final wishlistIds =
                (userData['wishlist'] as List<dynamic>?)?.length ?? 0;
            final expiryDate = _parseExpiry(userData['premiumExpiry']);
            final referralCode = userData['referralCode'] as String? ??
                (_uid?.substring(0, 6).toUpperCase() ?? '------');

            final isStillPremium = isPremium &&
                expiryDate != null &&
                expiryDate.isAfter(DateTime.now());

            return StreamBuilder<int>(
              stream: _reviewCountStream,
              builder: (context, reviewSnap) {
                final totalReviews = reviewSnap.data ?? 0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _uploadingPhoto
                                      ? null
                                      : _pickAndUploadPhoto,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _uploadingPhoto
                                              ? const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: AppColors.primary,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : profileImage != null
                                                  ? Image(
                                                      image: profileImage,
                                                      width: 84,
                                                      height: 84,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (_, __, ___) =>
                                                              const Icon(
                                                        Icons.person_rounded,
                                                        color:
                                                            AppColors.primary,
                                                        size: 40,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.person_rounded,
                                                      color: AppColors.primary,
                                                      size: 40,
                                                    ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  displayName,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: const Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                    await _loadUser(); // refresh nama & foto setelah balik
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: AppColors.primary),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Edit Profil',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isStillPremium) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6F4E37),
                                          Color(0xFF4E342E),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFD700),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Premium Member',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Berlaku hingga ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _statItem(
                                        'Ulasan', totalReviews.toString()),
                                    _dividerV(),
                                    _statItem(
                                        'Wishlist', wishlistIds.toString()),
                                    _dividerV(),
                                    _statItem('Poin', totalPoints.toString()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isStillPremium)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.premium),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6F4E37),
                                    Color(0xFF4E342E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Upgrade Premium',
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Akses filter advanced, hidden gems,\ndan wishlist unlimited!',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Mulai',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (isStillPremium)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.premium),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6F4E37),
                                    Color(0xFF4E342E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFFFD700),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Kamu sudah Premium!',
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Berlaku hingga ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}. Perpanjang?',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Perpanjang',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.monetization_on_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Poin',
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ),
                                    Text(
                                      '$totalPoints poin',
                                      style: AppTextStyles.headingSmall
                                          .copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.topup,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Top Up',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.people_outline_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kode Referral',
                                      style: AppTextStyles.caption.copyWith(
                                        color: const Color(0xFF9E9E9E),
                                      ),
                                    ),
                                    Text(
                                      referralCode,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontSize: 15,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.referral,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Bagikan',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _menuItem(
                              icon: Icons.history_rounded,
                              label: 'Riwayat Ulasan',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.reviewHistory,
                              ),
                            ),
                            _dividerH(),
                            _menuItem(
                              icon: Icons.receipt_long_outlined,
                              label: 'Riwayat Poin',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.pointHistory,
                              ),
                            ),
                            _dividerH(),
                            _menuItem(
                              icon: Icons.storefront_outlined,
                              label: 'Kerjasama & Sponsor',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.partnership,
                              ),
                            ),
                            _dividerH(),
                            _menuItem(
                              icon: Icons.settings_outlined,
                              label: 'Pengaturan',
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.settings,
                              ),
                            ),
                            _dividerH(),
                            _menuItem(
                              icon: Icons.help_outline_rounded,
                              label: 'Bantuan',
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.help),
                            ),
                            _dividerH(),
                            _menuItem(
                              icon: Icons.logout_rounded,
                              label: 'Keluar',
                              color: AppColors.error,
                              onTap: _handleLogout,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Kopiku Mana v1.0.0',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _dividerV() {
    return Container(height: 32, width: 1, color: const Color(0xFFE0E0E0));
  }

  Widget _dividerH() {
    return const Divider(
      height: 1,
      color: Color(0xFFF5F5F5),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF212121);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: c),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color != null ? c : const Color(0xFFBDBDBD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
