import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_constants.dart';
import 'app_routes.dart';
import 'cafe_model.dart';

/// Cafe tidak valid / kosong — disembunyikan dari daftar.
bool isCafeValid(CafeModel cafe) {
  final name = cafe.name.trim();
  if (name.isEmpty || name == '.' || name == '-' || name.length < 2) {
    return false;
  }
  if (cafe.address.trim().isEmpty &&
      cafe.city.trim().isEmpty &&
      cafe.district.trim().isEmpty) {
    return false;
  }
  return true;
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<CafeModel> _allCafes = [];
  List<CafeModel> _filtered = [];
  String _selectedCity = 'Semua Kota';
  String _selectedPrice = 'Semua Harga';
  String _selectedAtmosphere = 'Semua Suasana';
  bool _isLoading = true;
  String _searchQuery = '';

  final Map<String, String> _atmosphereMap = {
    'Semua Suasana': 'Semua Suasana',
    'Nongkrong': 'Nongkrong',
    'Nugas': 'Study Friendly',
    'Keluarga': 'Keluarga',
    'Outdoor': 'Outdoor',
    'Indoor': 'Indoor',
  };

  String get _cityLabel =>
      _selectedCity == 'Semua Kota' ? 'Kota' : _selectedCity;
  String get _priceLabel =>
      _selectedPrice == 'Semua Harga' ? 'Harga' : _selectedPrice;
  String get _atmosphereLabel =>
      _selectedAtmosphere == 'Semua Suasana' ? 'Suasana' : _selectedAtmosphere;

  @override
  void initState() {
    super.initState();
    _loadCafes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCafes() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _db.collection('cafes').get();
      final cafes = snap.docs
          .map((d) => CafeModel.fromMap(d.data(), d.id))
          .where(isCafeValid)
          .toList();
      if (mounted) {
        setState(() {
          _allCafes = cafes;
          _filtered = List.from(cafes)
            ..sort((a, b) {
              if (a.isSponsored && !b.isSponsored) return -1;
              if (!a.isSponsored && b.isSponsored) return 1;
              if (a.isSponsored && b.isSponsored) {
                return a.sponsorPriority.compareTo(b.sponsorPriority);
              }
              return 0;
            });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allCafes.where((cafe) {
        final matchCity =
            _selectedCity == 'Semua Kota' || cafe.city == _selectedCity;
        final matchPrice = _selectedPrice == 'Semua Harga' ||
            cafe.priceRange == _selectedPrice.split(' ').first;
        final firestoreValue =
            _atmosphereMap[_selectedAtmosphere] ?? _selectedAtmosphere;
        final matchAtmosphere = _selectedAtmosphere == 'Semua Suasana' ||
            cafe.atmosphere.contains(firestoreValue) ||
            cafe.category.contains(firestoreValue);
        final matchSearch = _searchQuery.isEmpty ||
            cafe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cafe.city.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            cafe.district.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchCity && matchPrice && matchAtmosphere && matchSearch;
      }).toList();

      _filtered.sort((a, b) {
        if (a.isSponsored && !b.isSponsored) return -1;
        if (!a.isSponsored && b.isSponsored) return 1;
        if (a.isSponsored && b.isSponsored) {
          return a.sponsorPriority.compareTo(b.sponsorPriority);
        }
        return 0;
      });
    });
  }

  void _showFilterSheet({
    required String title,
    required List<String> items,
    required String selected,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: items.map((item) {
                final isSelected = item == selected;
                return GestureDetector(
                  onTap: () {
                    onSelect(item);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          item,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF424242),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eksplorasi Cafe',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filtered.length} cafe ditemukan',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  _searchQuery = v;
                  _applyFilter();
                },
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Cari nama cafe atau kota...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: const Color(0xFFBDBDBD)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF9E9E9E), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: Color(0xFF9E9E9E), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilter();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip(
                    label: _cityLabel,
                    isActive: _selectedCity != 'Semua Kota',
                    onTap: () => _showFilterSheet(
                      title: 'Pilih Kota',
                      items: AppConstants.tapalKudaCities,
                      selected: _selectedCity,
                      onSelect: (v) {
                        setState(() => _selectedCity = v);
                        _applyFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _priceLabel,
                    isActive: _selectedPrice != 'Semua Harga',
                    onTap: () => _showFilterSheet(
                      title: 'Pilih Harga',
                      items: const ['Semua Harga', 'Budget', 'Mid', 'Premium'],
                      selected: _selectedPrice,
                      onSelect: (v) {
                        setState(() => _selectedPrice = v);
                        _applyFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: _atmosphereLabel,
                    isActive: _selectedAtmosphere != 'Semua Suasana',
                    onTap: () => _showFilterSheet(
                      title: 'Pilih Suasana',
                      items: _atmosphereMap.keys.toList(),
                      selected: _selectedAtmosphere,
                      onSelect: (v) {
                        setState(() => _selectedAtmosphere = v);
                        _applyFilter();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.coffee_outlined,
                                  size: 48, color: AppColors.disabled),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada cafe ditemukan',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: const Color(0xFF9E9E9E)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadCafes,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            itemCount: _filtered.length + 1,
                            itemBuilder: (_, i) {
                              if (i == _filtered.length) {
                                return _buildPartnershipBanner();
                              }
                              return _buildCafeItem(_filtered[i]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? Colors.white : const Color(0xFF212121),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCafeItem(CafeModel cafe) {
    return _HoverCard(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 80,
              child: _buildImage(cafe),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (cafe.isSponsored) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFFFFB300), width: 0.8),
                        ),
                        child: Text(
                          '★ Sponsor',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFE65100),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        cafe.name,
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                        '${cafe.district}, ${cafe.city}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cafe.priceDisplay,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _statusBadge(cafe.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnershipBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.partnership),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8D4B8)),
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
                Icons.storefront_rounded,
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
                    'Punya cafe?',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daftarkan cafe kamu untuk tampil di Kopiku Mana.',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(CafeModel cafe) {
    if (cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty) {
      return Image.network(
        cafe.photos.first,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.accent,
      child: const Center(
        child: Icon(Icons.coffee_rounded, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'aktif':
        color = AppColors.statusActive;
        label = 'Aktif';
        break;
      case 'tutup':
        color = AppColors.statusClosed;
        label = 'Tutup';
        break;
      default:
        color = AppColors.statusConfirm;
        label = 'Konfirmasi';
    }
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedSlide(
          offset: _hovered ? const Offset(0, -0.03) : Offset.zero,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.onTap,
                splashColor: AppColors.primary.withValues(alpha: 0.06),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
