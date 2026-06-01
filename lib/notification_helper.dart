import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static const String _lastVisitKey = 'last_visit';
  static const String _lastReviewReminderKey = 'last_review_reminder';
  static const String _notifReadKey = 'notif_read';

  // Simpan timestamp kunjungan sekarang
  static Future<void> recordVisit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVisitKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Cek berapa hari sejak kunjungan terakhir
  static Future<int> daysSinceLastVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisit = prefs.getInt(_lastVisitKey);
    if (lastVisit == null) return 0;
    final last = DateTime.fromMillisecondsSinceEpoch(lastVisit);
    return DateTime.now().difference(last).inDays;
  }

  // Generate list notifikasi lokal berdasarkan kondisi
  static Future<List<Map<String, dynamic>>> getNotifications(
      String userName) async {
    final prefs = await SharedPreferences.getInstance();
    final days = await daysSinceLastVisit();
    final List<Map<String, dynamic>> notifs = [];
    final now = DateTime.now();

    // Notifikasi sambutan (selalu ada)
    notifs.add({
      'id': 'welcome',
      'icon': '👋',
      'title': 'Selamat datang, $userName!',
      'body': 'Temukan cafe terbaik di Tapal Kuda favoritmu.',
      'time': _formatTime(now),
      'isNew': false,
    });

    // Pengingat jika tidak aktif > 3 hari
    if (days >= 3) {
      notifs.insert(0, {
        'id': 'inactive_reminder',
        'icon': '☕',
        'title': 'Udah $days hari nih!',
        'body':
            'Yuk eksplorasi cafe baru di sekitarmu. Siapa tau ada tempat nugas yang cozy!',
        'time': 'Baru saja',
        'isNew': true,
      });
    }

    // Pengingat nulis ulasan (setiap 7 hari)
    final lastReviewReminder = prefs.getInt(_lastReviewReminderKey);
    bool showReviewReminder = true;
    if (lastReviewReminder != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastReviewReminder);
      showReviewReminder = now.difference(last).inDays >= 7;
    }
    if (showReviewReminder) {
      await prefs.setInt(_lastReviewReminderKey, now.millisecondsSinceEpoch);
      notifs.insert(0, {
        'id': 'review_reminder',
        'icon': '⭐',
        'title': 'Tulis ulasan, dapat poin!',
        'body':
            'Setiap ulasan valid kamu bernilai +20 poin. Yuk bagikan pengalamanmu di cafe favoritmu!',
        'time': 'Minggu ini',
        'isNew': true,
      });
    }

    // Pengingat weekend (Sabtu/Minggu)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      notifs.insert(0, {
        'id': 'weekend',
        'icon': '🎉',
        'title': 'Weekend nih, kemana nih?',
        'body':
            'Cek cafe populer di Tapal Kuda, cocok buat santai bareng teman!',
        'time': 'Hari ini',
        'isNew': true,
      });
    }

    return notifs;
  }

  // Tandai semua sudah dibaca
  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifReadKey, true);
  }

  // Cek apakah ada notif belum dibaca
  static Future<bool> hasUnread(String userName) async {
    final notifs = await getNotifications(userName);
    return notifs.any((n) => n['isNew'] == true);
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
