import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class PartnershipScreen extends StatelessWidget {
  const PartnershipScreen({super.key});

  static const String _contactEmail = 'kopikumana@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6F4E37), Color(0xFF4E342E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Promosikan Cafe Anda',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jangkau pecinta kopi di Tapal Kuda. Cafe sponsor tampil di urutan teratas saat relevan dengan pencarian user.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Manfaat Kerjasama'),
                _benefitCard(
                  icon: Icons.vertical_align_top_rounded,
                  title: 'Prioritas di Hasil Cari',
                  body:
                      'Saat user mencari cafe yang sesuai, cafe Anda bisa tampil di urutan pertama.',
                ),
                const SizedBox(height: 8),
                _benefitCard(
                  icon: Icons.verified_rounded,
                  title: 'Badge Sponsor',
                  body:
                      'Tanda khusus di kartu cafe agar lebih menonjol dan terpercaya.',
                ),
                const SizedBox(height: 8),
                _benefitCard(
                  icon: Icons.groups_rounded,
                  title: 'Jangkauan Lokal',
                  body:
                      'Fokus wilayah Tapal Kuda: Jember, Banyuwangi, dan kota sekitarnya.',
                ),
                const SizedBox(height: 20),
                _sectionTitle('Cara Kerja'),
                _stepCard(
                  steps: const [
                    '1. Hubungi tim Kopiku Mana via email',
                    '2. Pilih paket kerjasama yang sesuai',
                    '3. Cafe diaktifkan status sponsor di aplikasi',
                    '4. Pantau performa & perpanjang paket',
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Paket (Contoh)'),
                _packageCard(
                  name: 'Basic',
                  duration: '30 hari',
                  highlight: false,
                  features: const [
                    'Prioritas hasil cari',
                    'Badge Sponsor',
                  ],
                ),
                const SizedBox(height: 8),
                _packageCard(
                  name: 'Premium',
                  duration: '90 hari',
                  highlight: true,
                  features: const [
                    'Semua fitur Basic',
                    'Prioritas lebih tinggi',
                    'Rekomendasi di section khusus',
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    'Harga paket disesuaikan — hubungi kami untuk penawaran resmi.',
                    style: AppTextStyles.caption
                        .copyWith(color: const Color(0xFF9E9E9E)),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('Hubungi Kami'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined,
                            color: AppColors.primary),
                        title: const Text('Email'),
                        subtitle: Text(
                          _contactEmail,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right_rounded, size: 20),
                        onTap: () => _showEmailSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8D4B8)),
                  ),
                  child: Text(
                    'Subjek email disarankan: [Sponsor] Nama Cafe - Kota\n\nReview pengguna tetap independen. Status sponsor tidak mengubah rating asli.',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF757575),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildHeader(BuildContext context) {
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
                  'Kerjasama & Sponsor',
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard({required List<String> steps}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF616161)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _packageCard({
    required String name,
    required String duration,
    required bool highlight,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.primary : const Color(0xFFEEEEEE),
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (highlight)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Populer',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            duration,
            style:
                AppTextStyles.caption.copyWith(color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f, style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showEmailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email Kerjasama', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            SelectableText(
              _contactEmail,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Salin alamat email lalu kirim dengan subjek:\n[Sponsor] Nama Cafe - Kota',
              style: AppTextStyles.caption
                  .copyWith(color: const Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
