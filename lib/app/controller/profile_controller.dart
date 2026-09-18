import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/driver_profile_model.dart';
import '../repository/profile_repository.dart';

class ProfileController extends GetxController {
  final _repo = ProfileRepository();
  final _auth = FirebaseAuth.instance;

  final profile = Rxn<DriverProfile>();
  final isLoading = false.obs;
  final isUploadingImage = false.obs;
  final error = ''.obs;

  bool get isProfileComplete{
    final p = profile.value;
    if (p == null) return false;

    // Safe null checks for all fields
    final name = p.displayName?.trim();
    final phone = p.phoneNumber?.trim();
    final vehicleType = p.vehicleType;
    final vehicleNumber = p.vehicleNumber?.trim();

    return name != null && name.length >= 2 &&
        phone != null && phone.isNotEmpty &&
        vehicleType != null && vehicleType.isNotEmpty &&
        vehicleNumber != null && vehicleNumber.isNotEmpty;
  }

  //  SAFE: Get missing fields for helpful error messages
  List<String> get missingProfileFields {
    final p = profile.value;
    if (p == null) return ['Profile not loaded'];

    final missing = <String>[];

    final name = p.displayName?.trim();
    if (name == null || name.length < 2) missing.add('Full Name');

    final phone = p.phoneNumber?.trim();
    if (phone == null || phone.isEmpty) missing.add('Phone Number');

    if (p.vehicleType == null || p.vehicleType!.isEmpty) missing.add('Vehicle Type');

    final vehicleNumber = p.vehicleNumber?.trim();
    if (vehicleNumber == null || vehicleNumber.isEmpty) missing.add('Vehicle Number');

    return missing;
  }

  //  SAFE: Validate and return user-friendly message
  String? validateProfileForTracking() {
    if (!isProfileComplete) {
      final missing = missingProfileFields;
      return 'Please complete your profile first:\n• ${missing.join('\n• ')}';
    }
    return null; // All good
  }

  String get uid => _auth.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (uid.isNotEmpty) _loadProfile();
  }

  Future<void> _loadProfile() async {

    // Guard: Don't run if user isn't logged in yet
    if (uid.isEmpty) {
      print('⚠️ UID empty, skipping profile load');
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final existing = await _repo.getProfile(uid);
      if (existing != null) {
        profile.value = existing;
      } else if (_auth.currentUser != null) {
        // First time: populate from Firebase Auth
        final user = _auth.currentUser!;
        profile.value = DriverProfile(
          uid: uid,
          displayName: user.displayName ?? 'Driver',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          authProvider: user.providerData.isNotEmpty ? user.providerData.first.providerId : 'email',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        //Save initial profile to Firestore
        await _repo.saveProfile(profile.value!);
      }
    } catch (e,stack) {
      print('Error loading profile: $e\n$stack');
      error.value = 'Failed to load profile';
    } finally {
      isLoading.value = false;
    }
  }

  // Upload image to Supabase Storage
  Future<void> pickAndUploadImage() async {
    //  1. Request permissions
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();    // Android 13+
    final storageStatus = await Permission.storage.request();

    // Check if ANY relevant permission is granted
    final hasPermission = Platform.isAndroid
        ? (await Permission.photos.isGranted ||
        await Permission.storage.isGranted ||
        cameraStatus.isGranted)
        : (cameraStatus.isGranted || photosStatus.isGranted);

    if (!hasPermission) {
      if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
        final openSettings = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Camera/Photos access is needed to upload a profile picture.'),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Open Settings', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
        if (openSettings == true) await openAppSettings();
      } else {
        Get.snackbar('Permission Denied', 'Camera/Photos access is required.',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
      return;
    }

    //   Show source picker dialog
    final source = await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Select Profile Photo'),
        content: const Text('Choose how you want to select your photo:'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: ImageSource.camera),
            child: const Text('Camera', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Get.back(result: ImageSource.gallery),
            child: const Text('Gallery', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (source == null) return;

//Pick image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: source, imageQuality: 85,
    maxWidth: 800);
    if (pickedFile == null) return;

    //Capture OLD file path before uploading
    String? oldFilePath;

    final oldUrl = profile.value?.photoUrl;
    if(oldUrl != null && oldUrl.contains('driver-profiles/')){
      //Extracts "profile/uid_123.jpg" from the full supabase url
    oldFilePath = oldUrl.split('driver-profiles/').last;
    print('old file to delete: $oldFilePath');
    }


    //Upload to New image to Supabase Storage
    isUploadingImage.value = true;
    error.value = '';
    try {
      final client = Supabase.instance.client;
      final bucket = 'driver-profiles';
      final fileName = 'profile/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final file = File(pickedFile.path);


      //upload with content type
      await client.storage
      .from(bucket)
      .upload(fileName, file,
      fileOptions: FileOptions(contentType: 'image/jpeg')
      );

      //Get public URL
      final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);

      //Update Firestore +UI
      final updated = profile.value!.copyWith(photoUrl: publicUrl);
      await _repo.saveProfile(updated);
      profile.value = updated;

      //Delete OLD image (only after successful upload and save
    if(oldFilePath != null && oldFilePath != fileName){
      try{
        await client.storage.from(bucket).remove([oldFilePath]);
        print('Old profile photo deleted: $oldFilePath');
    } catch(e) {
        print('Failed to delete old profile photo: $e');
    }
    }

      Get.snackbar('Success', 'Profile photo updated!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration (seconds: 2));

    } catch (e) {
      error.value = 'Upload failed: $e';
      Get.snackbar('Error', error.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3));
    } finally {
      isUploadingImage.value = false;
    }

  }

  //  Save text fields
  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    if (uid.isEmpty || profile.value == null) return false;


    //Validate all fields are filled
    if(name.trim().isEmpty){
      error.value = 'Full Name is required';
      return false;
    }
    if (phone.trim().isEmpty) {
      error.value = 'Phone Number is required';
      return false;
    }
    if (vehicleType.isEmpty) {
      error.value = 'Vehicle Type is required';
      return false;
    }
    if (vehicleNumber.trim().isEmpty) {
      error.value = 'Vehicle Number is required';
      return false;
    }
    //  Validate phone number: >= 10 digits (allow +, spaces, dashes)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 10) {
      error.value = 'Phone number must be at least 10 digits';
      return false;
    }
    // Validate vehicle number format (basic check)
    if (vehicleNumber.trim().length < 5) {
      error.value = 'Enter a valid vehicle number (min 5 characters)';
      return false;
    }

    //All validation passed -> prepare updated profile
    final updated = profile.value!.copyWith(
      displayName: name,
      phoneNumber: phone,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
    );

    final validationError = updated.validate();
    if (validationError != null) {
      error.value = validationError;
      return false;
    }

    isLoading.value = true;
    error.value = '';
    try {
      await _repo.saveProfile(updated);
      profile.value = updated;
      Get.snackbar('✅ Success', 'Profile saved successfully',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green);
      return true;
    } catch (e) {
      error.value = 'Save failed';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}