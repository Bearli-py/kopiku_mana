import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;
  String _loginError = '';

  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerReferralController = TextEditingController();
  bool _registerObscure = true;
  bool _registerLoading = false;
  String _registerError = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerReferralController.dispose();
    super.dispose();
  }

  String _makeReferralCode(String uid) {
    final clean = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length >= 6) return clean.substring(0, 6);
    return clean.padRight(6, 'X');
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _loginLoading = true;
      _loginError = '';
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _loginError = 'Email tidak terdaftar';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            _loginError = 'Email atau password salah';
            break;
          case 'invalid-email':
            _loginError = 'Format email tidak valid';
            break;
          case 'user-disabled':
            _loginError = 'Akun ini telah dinonaktifkan';
            break;
          case 'too-many-requests':
            _loginError = 'Terlalu banyak percobaan, coba lagi nanti';
            break;
          default:
            _loginError = 'Login gagal, coba lagi';
        }
      });
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _registerLoading = true;
      _registerError = '';
    });

    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final inputReferralCode =
        _registerReferralController.text.trim().toUpperCase();

    try {
      QueryDocumentSnapshot<Map<String, dynamic>>? referrerDoc;

      if (inputReferralCode.isNotEmpty) {
        final referrerQuery = await _db
            .collection('users')
            .where('referralCode', isEqualTo: inputReferralCode)
            .limit(1)
            .get();

        if (referrerQuery.docs.isEmpty) {
          setState(() {
            _registerLoading = false;
            _registerError = 'Kode referral tidak ditemukan';
          });
          return;
        }

        referrerDoc = referrerQuery.docs.first;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User gagal dibuat',
        );
      }

      await user.updateDisplayName(name);

      final uid = user.uid;
      final myReferralCode = _makeReferralCode(uid);
      final hasReferral = referrerDoc != null;
      final referrerId = referrerDoc?.id;

      if (referrerId == uid) {
        throw Exception('own-code');
      }

      final batch = _db.batch();
      final userRef = _db.collection('users').doc(uid);

      batch.set(
          userRef,
          {
            'uid': uid,
            'name': name,
            'email': email,
            'isPremium': false,
            'premiumExpiry': null,
            'totalPoints': hasReferral ? 15 : 0,
            'referralCode': myReferralCode,
            'hasUsedReferral': hasReferral,
            'usedReferralCode': hasReferral ? inputReferralCode : '',
            'wishlist': [],
            'photoUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      if (hasReferral && referrerId != null) {
        final referrerRef = _db.collection('users').doc(referrerId);

        batch.set(
          referrerRef,
          {'totalPoints': FieldValue.increment(15)},
          SetOptions(merge: true),
        );

        batch.set(_db.collection('point_history').doc(), {
          'userId': uid,
          'type': 'referral',
          'amount': 15,
          'description': 'Menggunakan kode referral $inputReferralCode',
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.set(_db.collection('point_history').doc(), {
          'userId': referrerId,
          'type': 'referral',
          'amount': 15,
          'description': 'Referral berhasil digunakan',
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.set(_db.collection('referral_history').doc(), {
          'referrerId': referrerId,
          'refereeId': uid,
          'code': inputReferralCode,
          'pointsAwarded': 15,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasReferral
                  ? 'Akun berhasil dibuat! Kamu dapat +15 poin referral.'
                  : 'Akun berhasil dibuat! Silakan masuk.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        _registerNameController.clear();
        _registerEmailController.clear();
        _registerPasswordController.clear();
        _registerReferralController.clear();
        _tabController.animateTo(0);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _registerError = 'Email sudah terdaftar';
            break;
          case 'invalid-email':
            _registerError = 'Format email tidak valid';
            break;
          case 'weak-password':
            _registerError = 'Password terlalu lemah, minimal 6 karakter';
            break;
          default:
            _registerError = 'Registrasi gagal, coba lagi';
        }
      });
    } catch (e) {
      setState(() {
        _registerError = 'Registrasi gagal, coba lagi';
      });
    } finally {
      if (mounted) setState(() => _registerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Image.asset(
                'assets/logo.png',
                width: 130,
                height: 86,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  '☕',
                  style: TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Kopiku Mana',
                style: AppTextStyles.headingLarge.copyWith(
                  color: const Color(0xFF212121),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Temukan cafe favoritmu di Tapal Kuda.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF9E9E9E),
                        labelStyle: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Masuk'),
                          Tab(text: 'Daftar'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoginForm(),
                          _buildRegisterForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF212121)),
              decoration: _inputDecoration(
                hint: 'contoh@email.com',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('Kata Sandi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _loginObscure,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF212121)),
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: _inputDecoration(
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _loginObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _loginObscure = !_loginObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password wajib diisi';
                if (v.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.forgotPassword);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    'Lupa kata sandi?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (_loginError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _errorBox(_loginError),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loginLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _loginLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Masuk',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nama Lengkap'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _registerNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF212121)),
              decoration: _inputDecoration(
                hint: 'Nama kamu',
                icon: Icons.person_outline,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                if (v.trim().length < 2) return 'Minimal 2 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('Email'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _registerEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF212121)),
              decoration: _inputDecoration(
                hint: 'contoh@email.com',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email wajib diisi';
                if (!v.contains('@')) return 'Format email tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('Kata Sandi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _registerPasswordController,
              obscureText: _registerObscure,
              textInputAction: TextInputAction.next,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: const Color(0xFF212121)),
              decoration: _inputDecoration(
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _registerObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _registerObscure = !_registerObscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password wajib diisi';
                if (v.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('Kode Referral Teman (Opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _registerReferralController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF212121),
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: _inputDecoration(
                hint: 'Contoh: ABC123',
                icon: Icons.card_giftcard_rounded,
              ).copyWith(counterText: ''),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                if (value.length != 6) return 'Kode referral harus 6 karakter';
                return null;
              },
            ),
            if (_registerError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _errorBox(_registerError),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _registerLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _registerLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Daftar',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: const Color(0xFF212121),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AppTextStyles.bodyMedium.copyWith(color: const Color(0xFFBDBDBD)),
      prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 0.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.0),
      ),
      errorStyle:
          AppTextStyles.caption.copyWith(color: const Color(0xFFE53935)),
    );
  }
}
