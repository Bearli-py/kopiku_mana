import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_routes.dart';
import 'cafe_model.dart';

class CafeListScreen extends StatefulWidget {
  final String title;
  final List<CafeModel> cafes;

  const CafeListScreen({
    super.key,
    required this.title,
    required this.cafes,
  });

  @override
  State<CafeListScreen> createState() => _CafeListScreenState();
}

class _CafeListScreenState extends State<CafeListScreen> {
  String _selectedCity = 'Semua';

  List<String> get _cities {
    final cities = widget.cafes
        .map((c) => c.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Semua', ...cities];
  }

  bool _isSponsorActive(CafeModel cafe) {
    if (!cafe.isSponsored) return false;
    if (cafe.sponsorUntil == null) return true;
    return cafe.sponsorUntil!.isAfter(DateTime.now());
  }

  List<CafeModel> get _filtered {
    final cafes = _selectedCity == 'Semua'
        ? List<CafeModel>.from(widget.cafes)
        : widget.cafes.where((c) => c.city.trim() == _selectedCity).toList();

    cafes.sort((a, b) {
      final aSponsored = _isSponsorActive(a);
      final bSponsored = _isSponsorActive(b);

      if (aSponsored && !bSponsored) return -1;
      if (!aSponsored && bSponsored) return 1;

      if (aSponsored && bSponsored) {
        final priorityCompare = b.sponsorPriority.compareTo(a.sponsorPriority);
        if (priorityCompare != 0) return priorityCompare;
      }

      if (a.distanceKm != null && b.distanceKm != null) {
        return a.distanceKm!.compareTo(b.distanceKm!);
      }

      return b.averageRating.compareTo(a.averageRating);
    });

    return cafes;
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          // Header rounded bottom
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(widget.title, style: AppTextStyles.headingSmall),
                        const Spacer(),
                        Text(
                          '${filtered.length} cafe',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      itemCount: _cities.length,
                      itemBuilder: (context, i) {
                        final city = _cities[i];
                        final isSelected = city == _selectedCity;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCity = city),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minWidth: 60),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Text(
                              city,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF757575),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // List cafe
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.coffee_outlined,
                            color: AppColors.disabled, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada cafe di kota ini',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: const Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildItem(context, filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, CafeModel cafe) {
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
                width: 80,
                height: 80,
                child: cafe.photos.isNotEmpty && cafe.photos.first.isNotEmpty
                    ? Image.network(
                        cafe.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                          const SizedBox(width: 8),
                        ] else
                          const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor(cafe.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${cafe.district}, ${cafe.city}',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                          ],
                        ),
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
                        if (cafe.distanceKm != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk_rounded,
                                  size: 11, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(
                                cafe.distanceDisplay,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (cafe.atmosphere.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: cafe.atmosphere
                            .take(2)
                            .map(
                              (a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.accent,
      child: const Center(
        child: Icon(Icons.coffee_rounded, color: AppColors.primary, size: 32),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aktif':
        return AppColors.statusActive;
      case 'tutup':
        return AppColors.statusClosed;
      default:
        return AppColors.statusConfirm;
    }
  }
}
