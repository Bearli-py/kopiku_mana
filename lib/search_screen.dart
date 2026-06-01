import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'cafe_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<CafeModel> _allCafes = [];
  List<CafeModel> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCafes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSponsorActive(CafeModel cafe) {
    if (!cafe.isSponsored) return false;
    if (cafe.sponsorUntil == null) return true;
    return cafe.sponsorUntil!.isAfter(DateTime.now());
  }

  void _sortSponsoredFirst(List<CafeModel> cafes) {
    cafes.sort((a, b) {
      final aSponsored = _isSponsorActive(a);
      final bSponsored = _isSponsorActive(b);

      if (aSponsored && !bSponsored) return -1;
      if (!aSponsored && bSponsored) return 1;

      if (aSponsored && bSponsored) {
        final priorityCompare = b.sponsorPriority.compareTo(a.sponsorPriority);
        if (priorityCompare != 0) return priorityCompare;
      }

      return b.averageRating.compareTo(a.averageRating);
    });
  }

  Future<void> _fetchCafes() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _db.collection('cafes').get();
      _allCafes =
          snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _results = [];
      } else {
        final q = query.toLowerCase();
        _results = _allCafes.where((cafe) {
          return cafe.name.toLowerCase().contains(q) ||
              cafe.city.toLowerCase().contains(q) ||
              cafe.district.toLowerCase().contains(q) ||
              cafe.atmosphere.any((a) => a.toLowerCase().contains(q)) ||
              cafe.category.any((c) => c.toLowerCase().contains(q));
        }).toList();

        _sortSponsoredFirst(_results);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          // Header rounded
          Container(
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
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primary, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _onSearch,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: const Color(0xFF212121),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari cafe, kota, suasana...',
                            hintStyle: AppTextStyles.bodyMedium
                                .copyWith(color: const Color(0xFFBDBDBD)),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF9E9E9E), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Color(0xFF9E9E9E), size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearch('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _searchController.text.isEmpty
                    ? _buildEmptySearch()
                    : _results.isEmpty
                        ? _buildNoResult()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (_, i) =>
                                _buildResultItem(_results[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: AppColors.disabled, size: 48),
          const SizedBox(height: 12),
          Text(
            'Cari cafe favoritmu',
            style: AppTextStyles.bodyMedium
                .copyWith(color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketik nama cafe, kota, atau suasana',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.coffee_outlined,
              color: AppColors.disabled, size: 48),
          const SizedBox(height: 12),
          Text(
            'Cafe tidak ditemukan',
            style: AppTextStyles.bodyMedium
                .copyWith(color: const Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci lain',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _sponsorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildResultItem(CafeModel cafe) {
    final isSponsor = _isSponsorActive(cafe);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.cafeDetail,
        arguments: cafe,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                width: 64,
                height: 64,
                child: cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty
                    ? Image.network(
                        cafe.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.accent,
                          child: const Icon(Icons.coffee_rounded,
                              color: AppColors.primary, size: 24),
                        ),
                      )
                    : Container(
                        color: AppColors.accent,
                        child: const Icon(Icons.coffee_rounded,
                            color: AppColors.primary, size: 24),
                      ),
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
                        _sponsorBadge(),
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
                          '${cafe.district}, ${cafe.city}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                      if (cafe.atmosphere.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cafe.atmosphere.first,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFBDBDBD), size: 20),
          ],
        ),
      ),
    );
  }
}
