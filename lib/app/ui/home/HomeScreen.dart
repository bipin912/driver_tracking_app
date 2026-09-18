import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../auth/auth_screen.dart';
import '../../controller/tracking_controller.dart';
import '../profile/profile_screen.dart';
import '../trip/trip_dashboard_screen.dart';

//  CONVERTED TO STATEFUL WIDGET
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //  Move controllers to State class
  late final TrackingController trackCtrl;
  late final ProfileController profileCtrl;

  @override
  void initState() {
    super.initState();
    //  Initialize controllers here
    trackCtrl = Get.put(TrackingController());
    profileCtrl = Get.put(ProfileController());
  }

  // NEW: Handle start tracking with profile validation
  void _handleStartTracking() {
    final profileError = profileCtrl.validateProfileForTracking();

    if (profileError != null) {
      //  1. Show snackbar with TAP-to-navigate option
      Get.snackbar('Profile Required', profileError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        onTap: (_) => Get.to(() => const ProfileScreen()), //  Tap to go
      );

      //  2. Auto-navigate after 800ms (so user sees the message)
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && Get.context != null) {
          Get.to(() => const ProfileScreen());
        }
      });
      return;
    }

    // Profile valid → start tracking
    trackCtrl.toggleTracking();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text('Logout',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm != true) return;

              // Show loading while logging out
              Get.dialog(
                const Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );

              // In the logout handler, replace your current cleanup with this:
              try {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn.instance.signOut();
                await GoogleSignIn.instance.disconnect();
              } catch (e) {
                Get.back(); // close loading
                Get.snackbar("Error", "Logout failed: $e",
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              Get.back(); // close loading dialog

              //  Delete ALL controllers BEFORE navigating
              // This disposes their Rx subscriptions cleanly
              Get.delete<TrackingController>(force: true);
              Get.delete<ProfileController>(force: true);
              try { Get.delete<AuthController>(force: true); } catch (_) {}

              Get.snackbar("Logged Out", "See you soon!",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2));

              await Future.delayed(const Duration(milliseconds: 300));

              // offAll clears the entire stack cleanly
              Get.offAll(() => const AuthScreen());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Obx reads profileCtrl.profile.value — fully reactive
            Obx(() {
              final name = profileCtrl.profile.value?.displayName?.trim().isNotEmpty == true
                  ? profileCtrl.profile.value!.displayName
                  : user?.displayName ?? 'Driver';
              return UserAccountsDrawerHeader(
                accountName: Text(name),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.lightBlueAccent,
                  child: Text(name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.black)),
                ),
                decoration: const BoxDecoration(color: Colors.green),
              );
            }),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('My Profile'),
              onTap: () {
                Get.back();
                Get.to(() => const ProfileScreen());
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Trip Dashboard'),
              onTap: () {
                Get.back();
                Get.to(() => TripDashboardScreen());
              },
            ),
            const Divider(),
            // ListTile(
            //   leading: const Icon(Icons.settings),
            //   title: const Text('Settings'),
            //   onTap: () => Get.back(),
            // ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Vertical centering
                crossAxisAlignment: CrossAxisAlignment.center, // Horizontal centering
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 24),

                  // Welcome text (already has textAlign)
                  Obx(() {
                    final name = profileCtrl.profile.value?.displayName?.trim().isNotEmpty == true
                        ? profileCtrl.profile.value!.displayName
                        : user?.displayName ?? 'Driver';
                    return Text("Welcome, $name!",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center); // Already centered
                  }),

                  // Email text - ADD textAlign
                  Text("Email: ${user?.email ?? 'N/A'}",
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),

                  //  UPDATED: Button uses _handleStartTracking()
                  Center(
                    child: Obx(() {
                      // Check profile completeness for visual styling only
                      final profileError = profileCtrl.validateProfileForTracking();
                      final isTracking = trackCtrl.isTracking.value;

                      return ElevatedButton.icon(
                        //  Use the new method for tap action
                        onPressed: isTracking
                            ? () => trackCtrl.toggleTracking()
                            : _handleStartTracking,

                        icon: Icon(
                          isTracking ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        label: Text(
                          isTracking ? "Stop Tracking" : "Start Tracking",
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          // Visual feedback: gray if disabled, green/red if active
                          backgroundColor: profileError != null
                              ? Colors.grey
                              : (isTracking ? Colors.red : Colors.green),
                          minimumSize: const Size(200, 50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),

                        // Show helpful tooltip on long-press (visual hint only)
                        onLongPress: profileError != null
                            ? () => Get.snackbar('Profile Incomplete', profileError,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                            icon: const Icon(Icons.warning_amber_rounded, color: Colors.white))
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row - ADD mainAxisSize.min + wrap in Center()
                  Obx(() => trackCtrl.isTracking.value
                      ? Center(
                    child: Column(
                      children: [
                        Text("Session: ${trackCtrl.sessionId.value}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        // Row with mainAxisSize.min so it only takes needed width
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.battery_std,
                                color: trackCtrl.batteryLevel.value < 20
                                    ? Colors.red
                                    : Colors.green),
                            const SizedBox(width: 4),
                            Text(
                                "${trackCtrl.batteryLevel.value}% ${trackCtrl.batteryStatus.value}"),
                            const SizedBox(width: 24),
                            const Icon(Icons.speed),
                            const SizedBox(width: 4),
                            Text(
                                "${trackCtrl.speedKmh.value.toStringAsFixed(1)} km/h"),
                          ],
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink()),

                  // Error text - wrap in Center + add textAlign
                  Obx(() => trackCtrl.errorMessage.isNotEmpty
                      ? Center(
                    child: Text(trackCtrl.errorMessage.value,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center),
                  )
                      : const SizedBox.shrink()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}