import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';

import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController photoController;

  bool isLoading = false;

  User get user => FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: user.displayName ?? '');

    photoController = TextEditingController(text: user.photoURL ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    photoController.dispose();
    super.dispose();
  }

  Future<void> updateProfile() async {
    try {
      setState(() => isLoading = true);

      await user.updateDisplayName(nameController.text.trim());

      await user.updatePhotoURL(photoController.text.trim());

      await user.reload();

      CustomSnackbar.show(
        title: "Success",
        message: "Profile updated successfully",
        type: SnackbarType.success,
      );

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      CustomSnackbar.show(
        title: "Error",
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final profileController = Get.find<ProfileController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Profile"), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Obx(
              () => Stack(
                children: [
                
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profileController.imagePath.value.isNotEmpty
                          ? profileController.imagePath.value
                          : (FirebaseAuth.instance.currentUser?.photoURL ?? ''),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 100,
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: profileController.pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            CustomText(
              currentUser.displayName ?? "User",
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),

            const SizedBox(height: 5),

            CustomText(currentUser.email ?? "", color: Colors.grey),

            const SizedBox(height: 35),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              enabled: false,
              initialValue: currentUser.email ?? "",
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
