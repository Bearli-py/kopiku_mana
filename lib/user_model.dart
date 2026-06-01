class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final int totalPoints;
  final String referralCode;
  final String? referredBy;
  final List<String> wishlist;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.isPremium,
    this.premiumExpiry,
    required this.totalPoints,
    required this.referralCode,
    this.referredBy,
    required this.wishlist,
    required this.createdAt,
  });

  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiry == null) return false;
    return premiumExpiry!.isAfter(DateTime.now());
  }

  bool get canAddToWishlist {
    if (isPremiumActive) return true;
    return wishlist.length < 3;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      avatarUrl: map['avatarUrl'],
      isPremium: map['isPremium'] ?? false,
      premiumExpiry: map['premiumExpiry'] != null
          ? (map['premiumExpiry'] as dynamic).toDate()
          : null,
      totalPoints: map['totalPoints'] ?? 0,
      referralCode: map['referralCode'] ?? '',
      referredBy: map['referredBy'],
      wishlist: List<String>.from(map['wishlist'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry,
      'totalPoints': totalPoints,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'wishlist': wishlist,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    bool? isPremium,
    DateTime? premiumExpiry,
    int? totalPoints,
    String? referralCode,
    String? referredBy,
    List<String>? wishlist,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      totalPoints: totalPoints ?? this.totalPoints,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      wishlist: wishlist ?? this.wishlist,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
