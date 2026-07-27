import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/utils/validation_helper.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = Get.find<ProfileController>();

  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _bioController;
  String? _nameError;
  String? _contactError;
  String? _bioError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _contactController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserDoc();
  }

  Future<void> _save() async {
    setState(() {
      _nameError = ValidationHelper.name(_nameController.text);

      _contactError = ValidationHelper.phone(
        _contactController.text,
        required: false,
      );

      _bioError = ValidationHelper.notes(
        _bioController.text,
        max: 160,
        field: 'Bio',
      );
    });

    if (_nameError != null || _contactError != null || _bioError != null) {
      return;
    }

    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'User not found',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Firebase Auth display name update
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        _nameController.text.trim(),
      );

      // Firestore profile data update
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'contact': _contactController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      CustomSnackbar.show(
        title: 'Success',
        message: 'Profile updated successfully',
        type: SnackbarType.success,
      );

      Get.back();
    } catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to update profile',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _loadUserDoc() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null && mounted) {
        _contactController.text = (data['contact'] as String?) ?? '';
        _bioController.text = (data['bio'] as String?) ?? '';
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            children: [
              // Header: close · title · Save
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SettingsUi.squareIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Get.back(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'edit_profile'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                    _saveButton(),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Avatar + change photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const ProfileAvatar(size: 90),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: GestureDetector(
                            onTap: _profile.pickImage,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 3,
                                ),
                              ),
                              child: const OnboardingLineIcon(
                                'camera',
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _profile.pickImage,
                      child: Text(
                        'change_photo'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              _label('field_label_name'.tr),
              _field(
                controller: _nameController,
                focused: true,
                keyboardType: TextInputType.name,

                errorText: _nameError,
              ),
              const SizedBox(height: 13),

              _label('field_label_email'.tr),
              _readOnlyField(user?.email ?? ''),
              const SizedBox(height: 13),

              _label('field_label_contact'.tr),
              _field(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'add_phone_number'.tr,
                errorText: _contactError,
              ),
              const SizedBox(height: 13),

              _label('field_label_bio'.tr),
              _field(
                controller: _bioController,
                maxLines: 3,
                hint: 'bio_hint'.tr,
                keyboardType: TextInputType.multiline,
                errorText: _bioError,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 40,
      width: 84,
      child: ElevatedButton(
        onPressed: () => _saving ? null : _save(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                'save'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Widget _field({
  //   required TextEditingController controller,
  //   bool focused = false,
  //   int maxLines = 1,
  //   String? hint,
  //   String? prefixText,
  //   TextInputType? keyboardType,
  //   String? Function(String?)? validator,
  //   List<TextInputFormatter>? inputFormatters,
  // }) {
  //   return Container(
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: AppColors.surfaceLight,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: focused ? AppColors.primary : AppColors.unselectedBorder,
  //         width: focused ? 1.5 : 1,
  //       ),
  //       boxShadow: focused
  //           ? [
  //               BoxShadow(
  //                 color: AppColors.primary.withValues(alpha: 0.1),
  //                 blurRadius: 0,
  //                 spreadRadius: 3,
  //               ),
  //             ]
  //           : null,
  //     ),
  //     padding: EdgeInsets.symmetric(
  //       horizontal: 14,
  //       vertical: maxLines > 1 ? 12 : 0,
  //     ),
  //     child: TextFormField(
  //       controller: controller,
  //       maxLines: maxLines,
  //       keyboardType: keyboardType,
  //       validator: validator,
  //       inputFormatters: inputFormatters,
  //       style: const TextStyle(
  //         fontSize: 16,
  //         fontWeight: FontWeight.w600,
  //         color: AppColors.textDark,
  //       ),
  //       decoration: InputDecoration(
  //         isDense: true,
  //         filled: false,
  //         prefixText: prefixText,
  //         prefixStyle: const TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w700,
  //           color: AppColors.textMedium,
  //         ),
  //         hintText: hint,
  //         hintStyle: const TextStyle(
  //           fontSize: 15,
  //           fontWeight: FontWeight.w500,
  //           color: AppColors.textHint,
  //         ),
  //         border: InputBorder.none,
  //         enabledBorder: InputBorder.none,
  //         focusedBorder: InputBorder.none,
  //         errorBorder: InputBorder.none,
  //         disabledBorder: InputBorder.none,
  //         focusedErrorBorder: InputBorder.none,
  //         contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 0 : 15),
  //       ),
  //     ),
  //   );
  // }

  Widget _field({
    required TextEditingController controller,
    bool focused = false,
    int maxLines = 1,
    String? hint,

    TextInputType? keyboardType,

    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : focused
                  ? AppColors.primary
                  : AppColors.unselectedBorder,
              width: errorText != null || focused ? 1.5 : 1,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? 12 : 0,
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              filled: false,
              isDense: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: maxLines > 1 ? 0 : 15,
              ),
            ),
          ),
        ),

        if (errorText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _readOnlyField(String value) {
    return Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.unselectedBorder),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium,
        ),
      ),
    );
  }
}
