class AppConstants {
  AppConstants._();

  static const String appName = 'Kopiku Mana';
  static const String appTagline = 'Temukan kopi favoritmu';

  static const List<String> tapalKudaCities = [
    'Semua Kota',
    'Jember',
    'Bondowoso',
    'Situbondo',
    'Banyuwangi',
    'Probolinggo',
    'Lumajang',
  ];

  static const List<String> priceRanges = [
    'Semua Harga',
    'Budget (< 20k)',
    'Mid (20k - 50k)',
    'Premium (> 50k)',
  ];

  static const List<String> atmosphereTags = [
    'Nongkrong',
    'Nugas',
    'Family',
    'Outdoor',
    'Indoor',
    'Cozy',
    'Aesthetic',
    'Quiet',
  ];

  static const String statusActive = 'aktif';
  static const String statusClosed = 'tutup';
  static const String statusConfirm = 'perlu_dikonfirmasi';

  static const int pointsReview = 20;
  static const int pointsReferral = 15;
  static const int pointsPremium7Days = 100;
  static const int pointsPremium30Days = 350;

  static const int maxWishlistFree = 3;
  static const int minReviewLength = 50;

  static const int daysActiveThreshold = 30;
  static const int daysConfirmThreshold = 90;

  static const String colUsers = 'users';
  static const String colCafes = 'cafes';
  static const String colReviews = 'reviews';
  static const String colPointTransactions = 'pointTransactions';
  static const String colReferrals = 'referrals';

  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusXL = 24;

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
}
