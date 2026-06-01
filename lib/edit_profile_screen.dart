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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();

  static const String _imgbbKey = '99a2b6d2c9cd97cf8cf369cb583a7e9b';

  String? _photoUrl;
  String? _photoBase64;
  bool _uploadingPhoto = false;
  bool _savingName = false;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _nameController.text = user.displayName ?? '';
    _photoUrl = _normalizePhotoUrl(user.photoURL);

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (!mounted || data == null) return;

      final name = _firstNonEmpty([data['name'], user.displayName]);
      final photoUrl = _normalizePhotoUrl(
        _firstNonEmpty([
          data['photoUrl'],
          data['photoURL'],
          data['avatarUrl'],
          user.photoURL,
        ]),
      );
      final photoBase64 = _firstNonEmpty([data['photoBase64']]);

      setState(() {
        if (name != null) _nameController.text = name;
        _photoUrl = photoUrl;
        _photoBase64 = photoBase64;
      });
    } catch (_) {
      return;
    }
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

      final bytes = await File(picked.path).readAsBytes();
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

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama tidak boleh kosong'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _savingName = true);
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _db.collection('users').doc(_uid).set({
        'name': name,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil disimpan!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyimpan, coba lagi'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? '';
    final profileImage = _profileImageProvider(_photoUrl, _photoBase64);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
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
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF212121),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profil', style: AppTextStyles.headingSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // ── Foto Profil ──
            Center(
              child: GestureDetector(
                onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: _uploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              )
                            : profileImage != null
                                ? Image(
                                    image: profileImage,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primary,
                                      size: 44,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 44,
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap foto untuk mengubah',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 28),
            // ── Form ──
            Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  Text(
                    'Nama',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.bodyMedium,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama kamu',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFFBDBDBD),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F5F2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email (read only)
                  Text(
                    'Email',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            email,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: Color(0xFFBDBDBD),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // ── Tombol Simpan ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingName ? null : _saveName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _savingName
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
