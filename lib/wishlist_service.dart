import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  static final _db = FirebaseFirestore.instance;
  static const int maxFree = 3;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Ambil list cafeId di wishlist user
  static Future<List<String>> getWishlistIds() async {
    if (_uid == null) return [];
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      if (!doc.exists) return [];
      final data = doc.data();
      final list = data?['wishlist'] as List<dynamic>? ?? [];
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // Cek apakah cafe sudah di wishlist
  static Future<bool> isWishlisted(String cafeId) async {
    final ids = await getWishlistIds();
    return ids.contains(cafeId);
  }

  // Tambah cafe ke wishlist
  // Return: 'added' | 'limit' | 'error'
  static Future<String> addToWishlist(String cafeId, bool isPremium) async {
    if (_uid == null) return 'error';
    try {
      final ids = await getWishlistIds();
      if (ids.contains(cafeId)) return 'added'; // sudah ada
      if (!isPremium && ids.length >= maxFree) return 'limit';

      await _db.collection('users').doc(_uid).set({
        'wishlist': FieldValue.arrayUnion([cafeId]),
      }, SetOptions(merge: true));
      return 'added';
    } catch (_) {
      return 'error';
    }
  }

  // Hapus cafe dari wishlist
  static Future<void> removeFromWishlist(String cafeId) async {
    if (_uid == null) return;
    try {
      await _db.collection('users').doc(_uid).update({
        'wishlist': FieldValue.arrayRemove([cafeId]),
      });
    } catch (_) {}
  }

  // Toggle wishlist
  // Return: 'added' | 'removed' | 'limit' | 'error'
  static Future<String> toggleWishlist(String cafeId, bool isPremium) async {
    final isIn = await isWishlisted(cafeId);
    if (isIn) {
      await removeFromWishlist(cafeId);
      return 'removed';
    } else {
      return await addToWishlist(cafeId, isPremium);
    }
  }
}
