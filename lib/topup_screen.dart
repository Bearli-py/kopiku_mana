import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedPackage = -1;
  int _selectedPayment = 0;
  bool _isLoading = false;

  static const String _backendUrl =
      'https://kopiku-backend-production.up.railway.app';

  String? get _uid => _auth.currentUser?.uid;

  final List<Map<String, dynamic>> _packages = [
    {
      'points': 100,
      'price': 10000,
      'priceLabel': 'Rp10.000',
      'bonus': null,
      'badge': null,
    },
    {
      'points': 250,
      'price': 25000,
      'priceLabel': 'Rp25.000',
      'bonus': null,
      'badge': null,
    },
    {
      'points': 600,
      'price': 30000,
      'priceLabel': 'Rp30.000',
      'bonus': '+100 bonus',
      'badge': 'TERBAIK',
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'label': 'GoPay',
      'short': 'GoPay',
      'type': 'ewallet',
      'icon': Icons.account_balance_wallet_rounded,
      'midtransPaymentType': 'gopay',
      'hint': 'Bayar lewat QRIS atau aplikasi GoPay melalui Midtrans Sandbox.',
    },
    {
      'label': 'ShopeePay',
      'short': 'ShopeePay',
      'type': 'ewallet',
      'icon': Icons.shopping_bag_outlined,
      'midtransPaymentType': 'shopeepay',
      'hint': 'Bayar lewat ShopeePay melalui Midtrans Sandbox.',
    },
    {
      'label': 'Bank BCA',
      'short': 'BCA',
      'type': 'bank',
      'icon': Icons.account_balance_rounded,
      'midtransPaymentType': 'bca_va',
      'hint': 'Bayar lewat Virtual Account BCA dari Midtrans Sandbox.',
    },
    {
      'label': 'Bank Mandiri',
      'short': 'Mandiri',
      'type': 'bank',
      'icon': Icons.account_balance_rounded,
      'midtransPaymentType': 'echannel',
      'hint': 'Bayar lewat Mandiri Bill Payment dari Midtrans Sandbox.',
    },
  ];

  int _pointsForPackage(Map<String, dynamic> package) {
    return package['bonus'] != null
        ? (package['points'] as int) + 100
        : package['points'] as int;
  }

  Future<void> _processTopUp() async {
    if (_selectedPackage == -1) {
      _showSnack('Pilih paket top up terlebih dahulu', AppColors.warning);
      return;
    }
    _showPaymentSummarySheet();
  }

  void _showPaymentSummarySheet() {
    final package = _packages[_selectedPackage];
    final method = _paymentMethods[_selectedPayment];
    final pointsToAdd = _pointsForPackage(package);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Ringkasan Pembayaran', style: AppTextStyles.headingSmall),
              const SizedBox(height: 6),
              Text(
                method['hint'] as String,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFF757575)),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE7E1)),
                ),
                child: Column(
                  children: [
                    _detailRow('Paket', '${package['points']} Poin'),
                    const SizedBox(height: 10),
                    _detailRow(
                      'Total Poin',
                      '$pointsToAdd Poin',
                      valueColor: AppColors.primary,
                      bold: true,
                    ),
                    const SizedBox(height: 10),
                    _detailRow(
                      'Nominal',
                      package['priceLabel'] as String,
                      bold: true,
                    ),
                    const SizedBox(height: 10),
                    _detailRow('Metode', method['label'] as String),
                    const Divider(height: 22, color: Color(0xFFE0E0E0)),
                    _detailRow(
                      'Status',
                      'Menunggu pembayaran',
                      valueColor: AppColors.warning,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Poin akan masuk otomatis setelah pembayaran berhasil dikonfirmasi Midtrans.',
                style: AppTextStyles.caption
                    .copyWith(color: const Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Batal',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF757575),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _createTopUpViaBackend();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Buat Transaksi',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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

  Future<void> _createTopUpViaBackend() async {
    final uid = _uid;
    if (uid == null) {
      _showSnack('Kamu harus login terlebih dahulu', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final package = _packages[_selectedPackage];
      final method = _paymentMethods[_selectedPayment];
      final pointsToAdd = _pointsForPackage(package);

      final response = await http
          .post(
            Uri.parse('$_backendUrl/create-transaction'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': uid,
              'packageId': 'pkg_${package['points']}',
              'points': pointsToAdd,
              'basePoints': package['points'],
              'bonusPoints': pointsToAdd - (package['points'] as int),
              'price': package['price'],
              'paymentMethod': method['label'],
              'midtransPaymentType': method['midtransPaymentType'],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['success'] == true) {
        final orderId = body['orderId'] as String;
        final snapRedirectUrl = body['snapRedirectUrl'] as String?;

        setState(() {
          _isLoading = false;
          _selectedPackage = -1;
        });

        _showPendingDialog(
          orderId,
          pointsToAdd,
          package['priceLabel'] as String,
          method['label'] as String,
          snapRedirectUrl,
        );
      } else {
        setState(() => _isLoading = false);
        _showSnack(
          body['message'] as String? ?? 'Gagal membuat transaksi',
          AppColors.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Gagal terhubung ke server, coba lagi', AppColors.error);
    }
  }

  void _showPendingDialog(
    String orderId,
    int points,
    String priceLabel,
    String methodLabel,
    String? snapRedirectUrl,
  ) {
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
                  Icons.hourglass_top_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text('Transaksi Dibuat!', style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Top up $points poin senilai $priceLabel via $methodLabel sedang menunggu pembayaran.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: const Color(0xFF757575)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  orderId,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              if (snapRedirectUrl != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse(snapRedirectUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Bayar Sekarang',
                      style: AppTextStyles.button.copyWith(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Nanti Saja',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style:
                AppTextStyles.caption.copyWith(color: const Color(0xFF9E9E9E)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: valueColor ?? const Color(0xFF212121),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(currentPoints)),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              _sectionTitle('Pilih Paket'),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _packageList()),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              _sectionTitle('Metode Pembayaran'),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _paymentList()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _header(int currentPoints) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 18,
      ),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Top Up Poin',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDE7E1), width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Poin',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currentPoints',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        'poin',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gunakan poin untuk aktivasi Premium dan fitur eksklusif.',
                  style: AppTextStyles.caption
                      .copyWith(color: const Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
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

  Widget _packageList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(_packages.length, (i) {
          final pkg = _packages[i];
          final isSelected = _selectedPackage == i;
          final totalPoints = _pointsForPackage(pkg);

          return GestureDetector(
            onTap: () => setState(() => _selectedPackage = i),
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
                    color: Colors.black
                        .withValues(alpha: isSelected ? 0.08 : 0.045),
                    blurRadius: isSelected ? 14 : 8,
                    offset: Offset(0, isSelected ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
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
                              '$totalPoints Poin',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (pkg['badge'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pkg['badge'] as String,
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
                          pkg['bonus'] == null
                              ? '${pkg['points']} poin utama'
                              : '${pkg['points']} poin utama + 100 bonus',
                          style: AppTextStyles.caption
                              .copyWith(color: const Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pkg['priceLabel'] as String,
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

  Widget _paymentList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(_paymentMethods.length, (i) {
          final method = _paymentMethods[i];
          final isSelected = _selectedPayment == i;

          return Column(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedPayment = i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : const Color(0xFFF8F5F2),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          method['icon'] as IconData,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF9E9E9E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['label'] as String,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 13,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF212121),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method['hint'] as String,
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF9E9E9E),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFD6D6D6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (i < _paymentMethods.length - 1)
                const Divider(
                  height: 1,
                  color: Color(0xFFF1ECE7),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _bottomButton() {
    final hasPackage = _selectedPackage != -1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                hasPackage ? AppColors.primary : const Color(0xFFBDBDBD),
            disabledBackgroundColor: const Color(0xFFBDBDBD),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  hasPackage ? 'Lanjutkan Pembayaran' : 'Pilih Paket Dulu',
                  style: AppTextStyles.button.copyWith(fontSize: 14),
                ),
        ),
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
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
