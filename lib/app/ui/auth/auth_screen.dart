//Stateless don't hold state
//GetX handles all state via AuthController. Obx() rebuilds Only when .obs values change

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/auth_controller.dart';

class AuthScreen extends StatefulWidget{
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  @override
  void initState() {
    super.initState();
    // CONCEPT: addPostFrameCallback runs AFTER first build completes
    // Ensures controller is injected before we call checkEmailVerification()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Get.find<AuthController>();
      if (ctrl.isVerificationPending.value) {
        ctrl.checkEmailVerification(); // Auto-check when user returns from email app
      }
    });
  }



  @override
  Widget build(BuildContext context) {


    //Get.put() injects the controller (creates once, reuses across rebuilds)
    final ctrl = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.white,

      //SingleChildScrollView prevents keyboard from covering inputs on small screens
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Obx(() {

            //FLOW: Reactively switch screen based on controller state
            if(ctrl.isVerificationPending.value){
              return _buildVerificationPendingScreen(ctrl);
            }
            return _buildAuthFormScreen(ctrl);
          }),
        )
      )
      );


  }

  //1.Email Verification Pending
  // Modern Verification Pending Screen
  Widget _buildVerificationPendingScreen(AuthController ctrl) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "your email";

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            //  Hero Icon with Soft Background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                size: 48,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 28),

            //  Clear Title & Context
            const Text(
              "Check Your Inbox",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We sent a secure verification link to\n$userEmail",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),

            //  Helpful Tip Box
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Don't see it? Check your Spam/Junk folder.",
                      style: TextStyle(color: Colors.amber.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            //  Primary Action: Verify Button (with loading state)
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: ctrl.isLoading.value ? null : ctrl.checkEmailVerification,
                icon: ctrl.isLoading.value
                    ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.check_circle),
                label: Text(ctrl.isLoading.value ? "Verifying..." : "I've Verified My Email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctrl.isLoading.value ? Colors.blue.withOpacity(0.7) : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ),

            const SizedBox(height: 16),

            //  Secondary Actions: Resend + Back
            Obx(() => TextButton(
              onPressed: ctrl.resendCooldown.value > 0 ? null : ctrl.resendVerificationEmail,
              child: Text(
                ctrl.resendCooldown.value > 0
                    ? "Resend available in ${ctrl.resendCooldown.value}s"
                    : "Resend Link",
                style: TextStyle(
                  color: ctrl.resendCooldown.value > 0 ? Colors.grey[400] : Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            ),
            Obx(() => ctrl.resendCooldown.value > 0
                ? LinearProgressIndicator(
              value: 1 - (ctrl.resendCooldown.value / 60),
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 4,
            )
                : const SizedBox.shrink(),
            ),

            TextButton(
              onPressed: () {
                ctrl.resetAuthState();
                ctrl.isVerificationPending.value = false;
                ctrl.isSignUpMode.value = false; // Force login mode
                ctrl.clearForm(); // Wipe everything
              },
              child: Text("← Back to Sign In", style: TextStyle(color: Colors.grey[700])),
            ),

            const SizedBox(height: 20),

            //  Error/Status Display
            Obx(() => ctrl.errorMessage.isNotEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ctrl.errorMessage.value,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  //Screen 2: Main Auth Form (Password /Magic Link/Google)
  Widget _buildAuthFormScreen(AuthController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ctrl.isSignUpMode.value ? "Create Account" : "Welcome Back",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(
          ctrl.isSignUpMode.value ? "Join as a driver" : "Sign in to continue" ,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),


        //Password Mode Input Fields
        Column(
          children: [
            //Driver Name (Sign-Up Only)
            if (ctrl.isSignUpMode.value) _input(ctrl.nameCtrl, "Driver Name", false),

            //Email(always)
            _input(ctrl.emailCtrl, "Email", false, isEmail: true),

            //Password(always)
            _input(ctrl.passwordCtrl, "Password", true, isVisible: ctrl.isPasswordVisible, onToggle: ctrl.togglePasswordVisibility),

            //Confirm Password (Sign-Up Only)
            if (ctrl.isSignUpMode.value) _input(ctrl.confirmPassCtrl, "Confirm Password", true, isVisible: ctrl.isConfirmPasswordVisible, onToggle: ctrl.toggleConfirmPasswordVisibility),
          ],
        ),
        const SizedBox(height: 12,),



        if (ctrl.errorMessage.isNotEmpty) Text(ctrl.errorMessage.value, style: const TextStyle(color: Colors.red, fontSize: 13)),
        const SizedBox(height: 24),

        //Dynamic Button: Changes label & action based on mode
        Obx (() => ElevatedButton(onPressed: ctrl.isLoading.value ? null : ctrl.handleAuth,
            child: ctrl.isLoading.value
                ? const SizedBox(
              height: 20, width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ):
            Text(ctrl.isSignUpMode.value? "Create Account" : "Sign In"),
            style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50)
          )
        ),
        ),
        const SizedBox(height: 20),

        //Toggle Login/SignUP
        Center(
          child: TextButton(
            onPressed: () {
              ctrl.isSignUpMode.toggle();
              ctrl.clearForm();
            },
            child: Text(
              ctrl.isSignUpMode.value ? "Already have an account? Sign In" : "Don't have an account? Sign Up",

          )
        ),
        ),
        const SizedBox(height: 20),

        //Divider

        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12),child: Text("OR"),),
            Expanded(child: Divider())
          ],
        ),

        const SizedBox(height: 20),

        //Google Button
        OutlinedButton.icon(
          onPressed: ctrl.isLoading.value ? null : ctrl.signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 40,),
          label: const Text("Continue with Google", style: TextStyle(color: Colors.black),),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.grey)
          )
        ),




      ],


    );
  }

  //Reusable TextField builder
Widget _input(TextEditingController ctrl, String hint, bool isPass,
    {bool isEmail = false, RxBool? isVisible, VoidCallback? onToggle}){
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: isPass ? !(isVisible?.value ?? false) : false, //Toggle obsecureText
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

          //Eye Icon for password fields
          suffixIcon: isPass
            ? Obx(() => IconButton(
                icon: Icon(
                  (isVisible?.value ?? false) ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey, size: 20,
                ),
                onPressed: onToggle, //Call the toggle callback
                tooltip: (isVisible?.value ?? false) ? 'Hide password': 'Show password',
              ))
              : null, //No icon for non-password fields
        ),
        style: TextStyle(fontSize: 16, color: Colors.black),

      )
    );
}
}