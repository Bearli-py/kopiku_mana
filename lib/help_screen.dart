import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_constants.dart';
import 'app_routes.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                _sectionTitle('Cara Pakai'),
                _helpCard(
                  children: [
                    _helpItem(
                      icon: Icons.explore_outlined,
                      title: 'Eksplorasi Cafe',
                      body:
                          'Cari cafe di Tapal Kuda. Filter kota & harga gratis. Filter suasana khusus Premium.',
                    ),
                    _divider(),
                    _helpItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'Wishlist',
                      body:
                          'Simpan cafe favorit. Akun gratis maks. 3 cafe. Premium unlimited.',
                    ),
                    _divider(),
                    _helpItem(
                      icon: Icons.rate_review_outlined,
                      title: 'Review',
                      body:
                          'Tulis review min. 3 kalimat untuk dapat +${AppConstants.pointsReview} poin.',
                    ),
                    _divider(),
                    _helpItem(
                      icon: Icons.diamond_outlined,
                      title: 'Hidden Gems',
                      body:
                          'Temukan cafe tersembunyi. Hanya untuk member Premium.',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Poin & Premium'),
                _helpCard(
                  children: [
                    _helpItem(
                      icon: Icons.stars_rounded,
                      title: 'Dapat Poin',
                      body:
                          'Review cafe (+${AppConstants.pointsReview}), referral (+${AppConstants.pointsReferral}), atau top up.',
                    ),
                    _divider(),
                    _helpItem(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Premium',
                      body:
                          '7 hari = ${AppConstants.pointsPremium7Days} poin, 30 hari = ${AppConstants.pointsPremium30Days} poin. Masa aktif bertambah dari tanggal expiry lama.',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('FAQ'),
                _faqTile(
                  question: 'Data cafe dari mana?',
                  answer:
                      'Data dikumpulkan dari kontribusi pengguna dan riset di wilayah Tapal Kuda (Jember-Banyuwangi).',
                ),
                _faqTile(
                  question: 'Kenapa cafe status Tutup?',
                  answer:
                      'Berdasarkan review terakhir. Kamu bisa konfirmasi lewat review baru.',
                ),
                _faqTile(
                  question: 'Bagaimana cara referral?',
                  answer:
                      'Masukkan kode referral saat daftar. Kamu dan pemberi kode masing-masing +${AppConstants.pointsReferral} poin.',
                ),
                const SizedBox(height: 20),
                _sectionTitle('Punya Cafe?'),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.partnership),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8D4B8)),
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
                          child: const Icon(Icons.storefront_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Promosikan cafe kamu',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kerjasama sponsor - tampil prioritas di hasil pencarian.',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFFBDBDBD)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _faqTile(
                  question: 'Apa itu cafe sponsor?',
                  answer:
                      'Cafe yang bekerjasama dengan Kopiku Mana. Saat cocok dengan pencarian user, cafe bisa tampil di urutan teratas dengan badge Sponsor.',
                ),
                _faqTile(
                  question: 'Bagaimana cara daftar sponsor?',
                  answer:
                      'Buka halaman Kerjasama & Sponsor di profil, atau ketuk kartu di atas. Hubungi email kopikumana@gmail.com dengan subjek [Sponsor] Nama Cafe - Kota.',
                ),
                const SizedBox(height: 20),
                _sectionTitle('Hubungi Kami'),
                _helpCard(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: const Icon(Icons.email_outlined,
                          color: AppColors.primary),
                      title: const Text('Email'),
                      subtitle: const Text('kopikumana@gmail.com'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _showContactSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionTitle('Legal'),
                _helpCard(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined,
                          color: AppColors.primary),
                      title: const Text('Kebijakan Privasi'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLegalSheet(
                        context,
                        'Kebijakan Privasi',
                        'Kopiku Mana menyimpan data akun (nama, email) dan aktivitas review untuk layanan aplikasi. Data tidak dijual ke pihak ketiga.',
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      title: const Text('Syarat & Ketentuan'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLegalSheet(
                        context,
                        'Syarat & Ketentuan',
                        'Dengan menggunakan aplikasi, pengguna setuju konten review bersifat jujur dan tidak mengandung SARA. Poin & premium bersifat simulasi untuk versi demo akademik.',
                      ),
                    ),
                  ],
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
                  'Bantuan',
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

  Widget _helpCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
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

  Widget _divider() => const Divider(height: 1, indent: 50, endIndent: 16);

  Widget _faqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            question,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: const Color(0xFF757575)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showContactSheet(BuildContext context) {
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
            Text('Hubungi Kami', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            SelectableText(
              'kopikumana@gmail.com',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Salin email di atas lalu kirim pertanyaanmu.',
              style: AppTextStyles.caption
                  .copyWith(color: const Color(0xFF9E9E9E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static void _showLegalSheet(
    BuildContext context,
    String title,
    String body,
  ) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            Text(
              body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: const Color(0xFF757575)),
            ),
          ],
        ),
      ),
    );
  }
}
