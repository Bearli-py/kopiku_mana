import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'cafe_model.dart';
import 'search_screen.dart';
import 'cafe_list_screen.dart';
import 'hidden_gems_screen.dart';
import 'notification_helper.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<CafeModel> _popularCafes = [];
  List<CafeModel> _topPickCafes = [];
  List<CafeModel> _nearbyCafes = [];
  List<CafeModel> _allCafes = [];
  List<CafeModel> _hiddenGems = [];
  bool _isLoading = true;
  bool _hasUnreadNotif = false;
  String _locationStatus = 'Mencari lokasi...';
  String _userName = 'Pengguna';
  bool _isPremium = false;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi,';
    if (hour < 15) return 'Selamat siang,';
    if (hour < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initLocation();
    NotificationHelper.recordVisit();
    _checkNotif();
    _checkPremium();
  }

  bool _isSponsorActive(CafeModel cafe) {
    if (!cafe.isSponsored) return false;
    if (cafe.sponsorUntil == null) return true;
    return cafe.sponsorUntil!.isAfter(DateTime.now());
  }

  Widget _sponsorBadge({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD36A)),
      ),
      child: Text(
        '★ Sponsor',
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF9A6A00),
          fontWeight: FontWeight.w700,
          fontSize: compact ? 9 : 10,
        ),
      ),
    );
  }

  Future<void> _checkPremium() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final isPremium = data['isPremium'] as bool? ?? false;
      final premiumExpiry = data['premiumExpiry'] as String?;
      DateTime? expiryDate;
      if (premiumExpiry != null) {
        expiryDate = DateTime.tryParse(premiumExpiry);
      }
      final isStillPremium =
          isPremium && expiryDate != null && expiryDate.isAfter(DateTime.now());
      if (mounted) setState(() => _isPremium = isStillPremium);
    } catch (_) {}
  }

  Future<void> _checkNotif() async {
    final has = await NotificationHelper.hasUnread(_userName);
    if (mounted) setState(() => _hasUnreadNotif = has);
  }

  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() => _userName = user.displayName!.split(' ').first);
      } else if (user.email != null) {
        setState(() => _userName = user.email!.split('@').first);
      }
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationStatus = 'Lokasi tidak aktif');
        await _loadData(null);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationStatus = 'Izin lokasi ditolak');
          await _loadData(null);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationStatus = 'Izin lokasi diblokir');
        await _loadData(null);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _loadData(position);
    } catch (e) {
      await _loadData(null);
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> _loadData(Position? position) async {
    setState(() => _isLoading = true);
    try {
      final allSnap = await _db.collection('cafes').limit(50).get();
      final allCafes =
          allSnap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();

      if (position != null) {
        for (var cafe in allCafes) {
          if (cafe.latitude != null && cafe.longitude != null) {
            cafe.distanceKm = _calculateDistance(
              position.latitude,
              position.longitude,
              cafe.latitude!,
              cafe.longitude!,
            );
          }
        }
      }

      final popular = List<CafeModel>.from(allCafes)
        ..sort((a, b) => b.averageRating.compareTo(a.averageRating));

      final topPicks = allCafes.where((c) => c.isTopPick).toList();
      final hiddenGems = allCafes.where((c) => c.isHiddenGem).toList();

      List<CafeModel> nearby = [];
      if (position != null) {
        nearby = allCafes.where((c) => c.distanceKm != null).toList()
          ..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
        setState(() => _locationStatus = 'Dekat lokasimu');
      }

      if (mounted) {
        setState(() {
          _allCafes = allCafes;
          _popularCafes = popular.take(5).toList();
          _topPickCafes = topPicks;
          _hiddenGems = hiddenGems;
          _nearbyCafes = nearby.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  void _openCafeList(String title, List<CafeModel> cafes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CafeListScreen(title: title, cafes: cafes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await FirebaseAuth.instance.currentUser?.reload();
          _loadUserName();
          await _initLocation();
          await _checkPremium();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                            Text(
                              'Halo, $_userName',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: const Color(0xFF212121),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NotificationScreen(userName: _userName),
                              ),
                            );
                            setState(() => _hasUnreadNotif = false);
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              if (_hasUnreadNotif)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _openSearch,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search,
                                color: Color(0xFF9E9E9E), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Cari cafe di Tapal Kuda...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFFBDBDBD),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              if (_topPickCafes.isNotEmpty) ...[
                _sectionHeader('Rekomendasi Hari Ini',
                    onTap: () =>
                        _openCafeList('Rekomendasi Hari Ini', _topPickCafes)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _topPickCafes.length,
                      itemBuilder: (_, i) =>
                          _buildTopPickCard(_topPickCafes[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              if (_hiddenGems.isNotEmpty) ...[
                _sectionHeader('Hidden Gems', onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HiddenGemsScreen(
                        cafes: _hiddenGems,
                        isPremium: _isPremium,
                      ),
                    ),
                  );
                  _checkPremium();
                }),
                SliverToBoxAdapter(
                  child: _buildHiddenGemsPageView(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
              _sectionHeaderWithSub(
                'Cafe Terdekat',
                _locationStatus,
                onTap: () => _openCafeList(
                    'Cafe Terdekat',
                    (_allCafes.where((c) => c.distanceKm != null).toList()
                          ..sort(
                              (a, b) => a.distanceKm!.compareTo(b.distanceKm!)))
                        .take(10)
                        .toList()),
              ),
              if (_nearbyCafes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off_outlined,
                              color: AppColors.disabled, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aktifkan lokasi untuk melihat cafe terdekat',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: _buildNearbyItem(_nearbyCafes[i]),
                    ),
                    childCount: _nearbyCafes.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              _sectionHeader('Populer di Tapal Kuda',
                  onTap: () =>
                      _openCafeList('Populer di Tapal Kuda', _popularCafes)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 210,
                  child: _popularCafes.isEmpty
                      ? _emptyState('Belum ada data')
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _popularCafes.length,
                          itemBuilder: (_, i) =>
                              _buildCafeCard(_popularCafes[i]),
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {bool showAll = true, VoidCallback? onTap}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            Text(title, style: AppTextStyles.headingSmall),
            const Spacer(),
            if (showAll)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'Lihat semua',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeaderWithSub(String title, String sub,
      {VoidCallback? onTap}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      sub,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTap,
              child: Text(
                'Lihat semua',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPickCard(CafeModel cafe) {
    final isSponsor = _isSponsorActive(cafe);

    return _PressCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              _buildCafeImage(cafe, height: 200, width: 260),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          cafe.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            cafe.city,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Top Pick',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (isSponsor) ...[
                      const SizedBox(width: 6),
                      _sponsorBadge(compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final PageController _hiddenGemController = PageController();
  int _currentHiddenGem = 0;

  Widget _buildHiddenGemsPageView() {
    final gems = _hiddenGems.take(5).toList();
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _hiddenGemController,
            itemCount: gems.length,
            onPageChanged: (i) => setState(() => _currentHiddenGem = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildHiddenGemCard(gems[i]),
            ),
          ),
        ),
        if (gems.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              gems.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentHiddenGem == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentHiddenGem == i
                      ? AppColors.primary
                      : const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHiddenGemCard(CafeModel cafe) {
    final isSponsor = _isSponsorActive(cafe);

    return _PressCard(
      onTap: _isPremium
          ? () => Navigator.pushNamed(
                context,
                AppRoutes.cafeDetail,
                arguments: cafe,
              )
          : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty
                    ? Image.network(
                        cafe.photos.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            _placeholderImage(220, double.infinity),
                      )
                    : _placeholderImage(220, double.infinity),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isPremium)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cafe.name,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            cafe.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white70, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            cafe.city,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (!_isPremium)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Upgrade Premium',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'untuk akses Hidden Gems',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.pushNamed(
                                context, AppRoutes.premium);
                            _checkPremium();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Upgrade Sekarang',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B5EA7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Hidden Gem',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (isSponsor) ...[
                      const SizedBox(width: 6),
                      _sponsorBadge(compact: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyItem(CafeModel cafe) {
    final isSponsor = _isSponsorActive(cafe);

    return _PressCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSponsor
              ? Border.all(color: const Color(0xFFFFD36A))
              : Border.all(color: Colors.transparent),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildCafeImage(cafe, height: 72, width: 72),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSponsor) ...[
                        const SizedBox(width: 6),
                        _sponsorBadge(compact: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${cafe.district} • ${cafe.city}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC107), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        cafe.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (cafe.distanceKm != null) ...[
                        const Icon(Icons.directions_walk_rounded,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          cafe.distanceDisplay,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _buildStatusDot(cafe.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeCard(CafeModel cafe) {
    final isSponsor = _isSponsorActive(cafe);

    return _PressCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: isSponsor
              ? Border.all(color: const Color(0xFFFFD36A))
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildCafeImage(cafe, height: 120, width: 175),
                  if (isSponsor)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _sponsorBadge(compact: true),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            cafe.city,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          cafe.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusDot(cafe.status),
                      ],
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

  Widget _buildCafeImage(CafeModel cafe,
      {required double height, required double width}) {
    final placeholder = _placeholderImage(height, width);

    if (cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty) {
      return SizedBox(
        height: height,
        width: width,
        child: ClipRect(
          child: Transform.scale(
            scale: 1.18,
            alignment: Alignment.topCenter,
            child: Image.network(
              cafe.photos.first,
              fit: BoxFit.cover,
              width: width,
              height: height,
              alignment: Alignment.topCenter,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder;
              },
              errorBuilder: (_, __, ___) => placeholder,
            ),
          ),
        ),
      );
    }
    return placeholder;
  }

  Widget _placeholderImage(double height, double width) {
    return Container(
      height: height,
      width: width,
      color: AppColors.accent,
      child: const Center(
        child: Icon(Icons.coffee_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'aktif':
        color = AppColors.statusActive;
        break;
      case 'tutup':
        color = AppColors.statusClosed;
        break;
      default:
        color = AppColors.statusConfirm;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(msg,
            style: AppTextStyles.bodyMedium
                .copyWith(color: const Color(0xFF9E9E9E))),
      ),
    );
  }
}

class _PressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressCard({required this.child, this.onTap});

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _pressed = true),
      onExit: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
