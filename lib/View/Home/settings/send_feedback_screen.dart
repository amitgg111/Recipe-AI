import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _controller = TextEditingController();
  int _type = 0; // 0 Idea, 1 Bug, 2 Praise
  bool _submitting = false;

  static const _types = [
    ['💡', 'Idea'],
    ['🐞', 'Bug'],
    ['❤️', 'Praise'],
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      CustomSnackbar.show(
        title: 'Empty feedback',
        message: 'Please write a little something first.',
        type: SnackbarType.warning,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = AuthService.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'uid': user?.uid,
        'email': user?.email,
        'type': _types[_type][1],
        'message': text,
        'appVersion': '1.0.0',
        'createdAt': FieldValue.serverTimestamp(),
      });
      CustomSnackbar.show(
        title: 'Thank you!',
        message: 'Your feedback has been sent.',
        type: SnackbarType.success,
      );
      Get.back();
    } catch (e) {
      CustomSnackbar.show(
        title: 'Error',
        message: 'Could not send feedback. Please try again.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsUi.header('Send feedback'),
              const SizedBox(height: 18),
              const Text(
                "We'd love to hear your thoughts. What kind of feedback do you have?",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 18),

              // Type chips
              Row(
                children: [
                  for (var i = 0; i < _types.length; i++) ...[
                    _typeChip(i),
                    if (i != _types.length - 1) const SizedBox(width: 9),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'YOUR FEEDBACK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      hintText: 'Tell us what you think…',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(int i) {
    final active = _type == i;
    return GestureDetector(
      onTap: () => setState(() => _type = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          '${_types[i][0]} ${_types[i][1]}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textBodyDark,
          ),
        ),
      ),
    );
  }
}
