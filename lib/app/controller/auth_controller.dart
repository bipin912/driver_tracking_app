import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracking_app/app/controller/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../ui/home/HomeScreen.dart';



//GetX controllers hold UI state and business logic.
//RxBool, RxString are reactive: when .value changes, obx() widgets auto-rebuild
class AuthController extends GetxController{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  //Reactive State Variables
  RxBool isLoading = false.obs;
  RxBool isSignUpMode = false.obs;
  RxBool isVerificationPending = false.obs;
  RxString errorMessage = ''.obs;
  RxBool isPasswordVisible = false.obs;
  RxBool isConfirmPasswordVisible = false.obs;
  RxInt resendCooldown = 0.obs;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();



  @override
  void onClose(){
    //Prevents memory leaks. Controllers must be disposed when screen leaves stack.
    _resendTimer?.cancel();
    emailCtrl.dispose(); passwordCtrl.dispose();
    nameCtrl.dispose(); confirmPassCtrl.dispose();
    super.onClose();
  }

  void resetAuthState() {
    isLoading.value = false;
    errorMessage.value = '';
    isVerificationPending.value = false;

    // Optional but recommended: clear fields for a fresh start
    emailCtrl.clear();
    passwordCtrl.clear();
    nameCtrl.clear();
    confirmPassCtrl.clear();

    //Reset  visibility states
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }


  void clearForm() {
    emailCtrl.clear();
    passwordCtrl.clear();
    nameCtrl.clear();
    confirmPassCtrl.clear();
    errorMessage.value = '';
    // isLoading stays false (already guaranteed by finally block)
  }

  //Toggle password visibility
  void togglePasswordVisibility(){
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility(){
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }




  // EMAIL/PASSWORD AUTH
  Future<void> handleAuth() async {
    if (!_validate()) return;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      User? user;

      if (isSignUpMode.value) {
        // CREATE ACCOUNT
        final cred = await _auth.createUserWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text.trim()
        );
        user = cred.user;

        //Save driver name to firestore(source of truth)
        try {
          final driverName = nameCtrl.text.trim();
          await user?.updateDisplayName(driverName);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .set({
            'displayName': driverName,
            'email': user?.email,
            'created_at': FieldValue.serverTimestamp(),
            'authProvider': 'email',
          });
        }catch(e){
          print("Error saving driver name: $e");
        }


        //  SEND VERIFICATION EMAIL
        await user?.sendEmailVerification();
        Get.snackbar("Account Created", "Check your inbox to verify your email.");

        // CRITICAL FIX: Show verification screen IMMEDIATELY
        isVerificationPending.value = true;

      } else {
        // SIGN IN
        final cred = await _auth.signInWithEmailAndPassword(
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text.trim()
        );
        user = cred.user;

        //  BLOCK LOGIN IF NOT VERIFIED
        if (user != null && !user.emailVerified) {
          await _auth.signOut(); // Security: force re-auth after verification
          errorMessage.value = "Email not verified. Check your inbox.";
          isVerificationPending.value = true;
          isLoading.value = false;
          return; // Stop here → UI shows verification screen
        }

        // IF VERIFIED → GO TO HOME
        if (user != null) {

          try {
            if (!Get.isRegistered<ProfileController>()) {
              Get.put(ProfileController(), permanent: true); // Keep alive across app
            } else {
              Get.find<ProfileController>().onInit();
            }
          } catch (_) {}


          isVerificationPending.value = false;
          Get.offAll(() => HomeScreen());
        }
      }
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _mapError(e.code);
    } finally {
      isLoading.value = false;
    }
  }

  //GOOGLE SIGN_IN
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }//user cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null){
        //Check Firestore for existing driver name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if(userDoc.exists && userDoc.data()?['displayName'] != null){
          //Driver name exists in firestore -> Use It (dominates google name)
          final driverName = userDoc.data()?['displayName'];
          await user.updateDisplayName(driverName);
        } else {
          //No name → save Google display name to Firestore
          final googleName = user.displayName ?? 'Driver';
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': googleName,
            'email': user.email,
            'created_at': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          }, SetOptions(merge: true));

        }
      }
      //  Initialize ProfileController after auth succeeds
      try {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController(), permanent: true);
        } else {
          Get.find<ProfileController>().onInit();
        }
      } catch (_) {} // Safe: Profile init is non-critical for navigation

      Get.snackbar("Success", "Signed in with Google!");
      Get.offAll(() => HomeScreen());
    } catch (e) {
      errorMessage.value =
      "Google Sign-In failed. $e";
      print('Google Sign-In error: $e');
    } finally {
      isLoading.value = false;
    }
  }





  //VERIFICATION HELPERS
    Timer? _resendTimer;
    Future<void> resendVerificationEmail() async {
      if (resendCooldown.value > 0) return; //Block if cooling down

      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar("Resent", "Check your inbox again.");

        //Start 60-second cooldown
        resendCooldown.value = 60;

        _resendTimer?.cancel(); //Cancel any existing timer
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (resendCooldown.value > 0) {
            resendCooldown.value--; //this automatically updates the UI every second
          } else {
            timer.cancel();
          }
        });
      }
    }


  Future<void> checkEmailVerification() async {
    //  1. CLEAR OLD ERROR IMMEDIATELY (makes UI clean on tap)
    errorMessage.value = '';
    isLoading.value = true; // Shows spinner, disables button

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.reload(); // Force fresh server check

        if (_auth.currentUser?.emailVerified == true) {
          isVerificationPending.value = false;
          Get.snackbar("Verified", "Logging you in...");
          Get.offAll(() => HomeScreen());
        } else {
          //  2. REAPPEAR FRESH ERROR if still unverified
          errorMessage.value = "Still unverified. Please click the link in your inbox first.";
        }
      } catch (e) {
        errorMessage.value = "Connection error. Please check your internet.";
      } finally {
        isLoading.value = false; // Always re-enable button
      }
    }
  }



    //VALIDATION & ERRORS
    bool _validate() {
      final email = emailCtrl.text.trim();
      final pass = passwordCtrl.text.trim();
      if (email.isEmpty || !GetUtils.isEmail(email)){
        errorMessage.value = "Enter a valid email"; return false;
      }
      if(pass.length < 6){
        errorMessage.value = "Password must be at least 6 characters"; return false;
      }
      if(isSignUpMode.value){
        if(nameCtrl.text.trim().isEmpty){
          errorMessage.value = "Name required"; return false;
        }
        if(confirmPassCtrl.text.trim() != pass){
          errorMessage.value = "Passwords do not match"; return false;
        }

      }
      return true;
    }

    String _mapError(String code){
      switch (code) {
        case 'user-not-found' : return "No account found";
        case 'wrong-password' : return "Incorrect password";
        case 'email-already-in-use' : return "Email already registered";
        case 'weak-password' : return "Password too weak";
        default: return "Authentication failed. Try again.";
      }
    }

  }



