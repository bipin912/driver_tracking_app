import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/driver_profile_model.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;
  static const _collection = 'users';

  //  Save/update profile (merge preserves auth fields)
  Future<void> saveProfile(DriverProfile profile) async {
    await _db.collection(_collection).doc(profile.uid).set(
      profile.toMap(),
      SetOptions(merge: true),
    );
  }

  //  Load profile
  Future<DriverProfile?> getProfile(String uid) async {
    if (uid.isEmpty) return null; //Prevent crash on empty string
    try {
      final doc = await _db.collection(_collection).doc(uid).get();
      return doc.exists
          ? DriverProfile.fromFirestore(doc.data()!, doc.id)
          : null;
    } catch (e) {
      print('Error fetching profile for $uid: $e');
      return null;
    }
  }

  //  Create initial profile on first login
  Future<void> createInitialProfile(DriverProfile profile) async {
    await _db.collection(_collection).doc(profile.uid).set({
      ...profile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}