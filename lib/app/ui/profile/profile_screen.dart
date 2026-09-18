import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/profile_controller.dart';
import '../home/HomeScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileController _ctrl;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vehicleNumCtrl;
  String _selectedVehicleType = 'Motorcycle';
  final _vehicleTypes = ['Motorcycle', 'Scooter', 'Car', 'Van', 'Truck', 'Auto Rickshaw', 'Bicycle'];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ProfileController());
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _vehicleNumCtrl = TextEditingController();

    _prefillForm();
    _ctrl.profile.listen((_) => _prefillForm());
  }

  void _prefillForm() {
    final p = _ctrl.profile.value;
    if (p == null || !mounted) return;

    _nameCtrl.text = p.displayName;
    _phoneCtrl.text = p.phoneNumber ?? '';
    _vehicleNumCtrl.text = p.vehicleNumber ?? '';
    if (_vehicleTypes.contains(p.vehicleType)) {
      _selectedVehicleType = p.vehicleType!;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _vehicleNumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        actions: [
          // Show loading spinner in AppBar if saving
          Obx(() => _ctrl.isLoading.value
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.profile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(_ctrl.error.value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _ctrl.onInit,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return _buildForm();
      }),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image Upload
            GestureDetector(
              onTap: _ctrl.pickAndUploadImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _ctrl.profile.value?.photoUrl != null
                        ? NetworkImage(_ctrl.profile.value!.photoUrl!)
                        : null,
                    child: _ctrl.profile.value?.photoUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Obx(() => _ctrl.isUploadingImage.value
                      ? const Positioned.fill(
                    child: CircleAvatar(
                      radius: 50, backgroundColor: Colors.black54,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                      : const Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      radius: 18, backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  )),
                ],
              ),
            ),
            const Text('Tap to change photo', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),

            _buildTextField(_nameCtrl, 'Full Name', Icons.person, 'Your full name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Name is required';
                if (value.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },),
            const SizedBox(height: 16),
            _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone, '+977 98XXXXXXXX', keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Phone is required';
                final clean = value.replaceAll(RegExp(r'[^\d]'), '');
                if (clean.length < 10) return 'Must be at least 10 digits';
                return null;
              },),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _vehicleTypes.contains(_selectedVehicleType) ? _selectedVehicleType : _vehicleTypes.first,
              decoration: const InputDecoration(labelText: 'Vehicle Type', prefixIcon: Icon(Icons.directions_car), border: OutlineInputBorder()),
              items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedVehicleType = v!),
            ),
            const SizedBox(height: 16),
            _buildTextField(_vehicleNumCtrl, 'Vehicle Number', Icons.confirmation_number, 'BA 12 PA 1234', textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vehicle number is required';
                if (value.trim().length < 5) return 'Enter a valid vehicle number';
                return null;
              },),
            const SizedBox(height: 24),

            //  Error message display
            Obx(() => _ctrl.error.value.isNotEmpty
                ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_ctrl.error.value, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
            )
                : const SizedBox.shrink()),

            //  Save button with loading indicator
            Obx(() => ElevatedButton(
              onPressed: _ctrl.isLoading.value ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _ctrl.isLoading.value
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl,
      String label,
      IconData icon,
      String hint, {
    TextInputType? keyboardType,
        TextCapitalization textCapitalization = TextCapitalization.none,
        String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint, border: const OutlineInputBorder()),
    );
  }

  //  Save with guaranteed feedback + navigation
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading dialog for better UX
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final success = await _ctrl.saveProfile(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      vehicleType: _selectedVehicleType,
      vehicleNumber: _vehicleNumCtrl.text,
    );

    // Close loading dialog
    if (Get.isDialogOpen ?? false) Get.back();

    if (success && mounted) {
      //  Show success message + navigate to HomeScreen
      Get.snackbar('Success', 'Profile saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2));

      // Small delay to let user see snackbar before navigating
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAll(() => HomeScreen()); // Navigate to HomeScreen
    }
  }
}