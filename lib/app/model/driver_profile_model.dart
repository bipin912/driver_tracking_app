import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? vehicleType;
  final String? vehicleNumber;
  final String authProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.vehicleType,
    this.vehicleNumber,
    required this.authProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  //  Create from Firestore document
  factory DriverProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return DriverProfile(
      uid: uid,
      displayName: data['displayName'] ?? 'Driver',
      email: data['email']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      vehicleType: data['vehicleType']?.toString(),
      vehicleNumber: data['vehicleNumber']?.toString(),
      authProvider: data['authProvider']?.toString() ?? 'unknown',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  //  Create from Firebase Auth User (first login)
  factory DriverProfile.fromFirebaseUser(User user) {
    return DriverProfile(
      uid: user.uid,
      displayName: user.displayName ?? 'Driver',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      authProvider: user.providerData.isNotEmpty ? user.providerData.first.providerId : 'email',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  //  Convert to Firestore map (updatable fields only)
  Map<String, dynamic> toMap() => {
    'displayName': displayName.trim(),
    'email': email,
    'phoneNumber': phoneNumber?.trim(),
    'photoUrl': photoUrl,
    'vehicleType': vehicleType,
    'vehicleNumber': vehicleNumber?.trim().toUpperCase(),
    'authProvider': authProvider,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  //  Immutable copy with updates
  DriverProfile copyWith({
    String? displayName,
    String? phoneNumber,
    String? vehicleType,
    String? vehicleNumber,
    String? photoUrl,
  }) {
    return DriverProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      authProvider: authProvider,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  //  Validation
  String? validate() {
    if (displayName.trim().length < 2) return 'Enter a valid name';
    if (phoneNumber?.trim().isNotEmpty == true &&
        !RegExp(r'^\+?[\d\s\-()]{7,15}$').hasMatch(phoneNumber!.trim())) {
      return 'Invalid phone number';
    }
    if (vehicleNumber?.trim().isNotEmpty == true && vehicleNumber!.trim().length < 5) {
      return 'Invalid vehicle number';
    }
    return null;
  }

  bool get isProfileComplete =>
      phoneNumber?.isNotEmpty == true && vehicleType?.isNotEmpty == true;
}