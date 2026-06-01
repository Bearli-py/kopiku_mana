import 'package:cloud_firestore/cloud_firestore.dart';

class CafeModel {
  final String cafeId;
  final String name;
  final String city;
  final String district;
  final String address;
  final List<String> photos;
  final String priceRange;
  final List<String> atmosphere;
  final List<String> category;
  final bool hasWifi;
  final double averageRating;
  final int totalReviews;
  final String status;
  final bool isTopPick;
  final bool isHiddenGem;
  final DateTime? createdAt;
  final double? latitude;
  final double? longitude;
  double? distanceKm;

  // ── Sponsor fields ──
  final bool isSponsored;
  final DateTime? sponsorUntil;
  final int sponsorPriority;

  CafeModel({
    required this.cafeId,
    required this.name,
    required this.city,
    required this.district,
    required this.address,
    required this.photos,
    required this.priceRange,
    required this.atmosphere,
    required this.category,
    required this.hasWifi,
    required this.averageRating,
    required this.totalReviews,
    required this.status,
    required this.isTopPick,
    required this.isHiddenGem,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.distanceKm,
    // ── Sponsor fields ──
    this.isSponsored = false,
    this.sponsorUntil,
    this.sponsorPriority = 99,
  });

  factory CafeModel.fromMap(Map<String, dynamic> map, String id) {
    double rating = 0.0;
    if (map['rating'] != null) {
      rating = double.tryParse(map['rating'].toString()) ?? 0.0;
    }

    List<String> photos = [];
    if (map['photos'] != null && map['photos'] is List) {
      photos = (map['photos'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> atmosphere = [];
    if (map['atmosphere'] != null && map['atmosphere'] is List) {
      atmosphere = (map['atmosphere'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    List<String> category = [];
    if (map['category'] != null) {
      if (map['category'] is List) {
        category = (map['category'] as List)
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        category = [map['category'].toString()];
      }
    }

    int totalReviews = 0;
    if (map['totalReviews'] != null) {
      totalReviews = int.tryParse(map['totalReviews'].toString()) ?? 0;
    }

    DateTime? createdAt;
    if (map['createdAt'] != null && map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }

    double? latitude;
    if (map['latitude'] != null) {
      latitude = double.tryParse(map['latitude'].toString());
    }

    double? longitude;
    if (map['longitude'] != null) {
      longitude = double.tryParse(map['longitude'].toString());
    }

    // ── Sponsor parsing ──
    DateTime? sponsorUntil;
    if (map['sponsorUntil'] != null && map['sponsorUntil'] is Timestamp) {
      sponsorUntil = (map['sponsorUntil'] as Timestamp).toDate();
    }

    final now = DateTime.now();
    final isSponsored = map['isSponsored'] == true &&
        sponsorUntil != null &&
        sponsorUntil.isAfter(now);

    return CafeModel(
      cafeId: id,
      name: map['name']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      photos: photos,
      priceRange: map['priceRange']?.toString() ?? 'Mid',
      atmosphere: atmosphere,
      category: category,
      hasWifi: map['hasWifi'] == true,
      averageRating: rating,
      totalReviews: totalReviews,
      status: map['status']?.toString() ?? 'aktif',
      isTopPick: map['isTopPick'] == true || map['isTopPIck'] == true,
      isHiddenGem: map['isHiddenGem'] == true,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      // ── Sponsor ──
      isSponsored: isSponsored,
      sponsorUntil: sponsorUntil,
      sponsorPriority:
          int.tryParse(map['sponsorPriority']?.toString() ?? '') ?? 99,
    );
  }

  String get priceDisplay {
    switch (priceRange) {
      case 'Budget':
        return '< Rp20k';
      case 'Mid':
        return 'Rp20k - 50k';
      case 'Premium':
      case 'high':
        return '> Rp50k';
      default:
        return priceRange;
    }
  }

  String get distanceDisplay {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}
