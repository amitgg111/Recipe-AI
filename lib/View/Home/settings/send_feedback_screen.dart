import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _controller = TextEditingController();
  int _type = 0; // 0 Idea, 1 Bug, 2 Praise
  bool _submitting = false;
  XFile? _shot; // optional screenshot attachment

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null && mounted) setState(() => _shot = file);
  }

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

      // Upload the optional screenshot to Firebase Storage first. A failure
      // here (e.g. storage rules/offline) must not lose the text feedback, so
      // it's non-fatal — we just submit without the attachment.
      String? screenshotUrl;
      await _showSuccessDialog();
      if (mounted) Get.back();
      if (_shot != null) {
        try {
          final uid = user?.uid ?? 'anonymous';
          final ref = FirebaseStorage.instance.ref(
            'feedback/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await ref.putFile(File(_shot!.path));
          screenshotUrl = await ref.getDownloadURL();
        } catch (_) {
          screenshotUrl = null;
        }
      }

      // Store under the signed-in user's document — permitted by the existing
      // owner-write rule (users/{uid}/{collection}/{docId}). Falls back to a
      // top-level collection only if somehow not signed in.
      final feedbackCol = user != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('feedback')
          : FirebaseFirestore.instance.collection('feedback');
      await feedbackCol.add({
        'uid': user?.uid,
        'email': user?.email,
        'type': _types[_type][1],
        'message': text,
        'screenshotUrl': screenshotUrl,
        'appVersion': '1.0.0',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _submitting = false);
      // A clear confirmation "moment": an animated success dialog, then pop
      // back to Settings when the user taps Done.
    } catch (e) {
      debugPrint('SendFeedback: submit failed → $e');
      CustomSnackbar.show(
        title: 'Error',
        message: 'Could not send feedback. Please try again.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Animated success confirmation shown after feedback is sent.
  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 44),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark badge with a spring "pop".
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutBack,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenBgLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const OnboardingLineIcon(
                    'check',
                    color: AppColors.green,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your feedback has been sent — it helps us make Recipe AI better.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15,
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            if (i != _types.length - 1)
                              const SizedBox(width: 9),
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
                      SizedBox(
                        height: 150,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
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
                      const SizedBox(height: 14),
                      // Add a screenshot (optional)
                      GestureDetector(
                        onTap: _pickScreenshot,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            _shot == null
                                ? SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CustomPaint(
                                      painter: const _DashedRRectPainter(
                                        color: Color(0xFFD8CFBE),
                                        radius: 14,
                                        strokeWidth: 1.5,
                                      ),
                                      child: Center(
                                        child: SvgPicture.string(
                                          _kCameraSvg,
                                          width: 24,
                                          height: 24,
                                        ),
                                      ),
                                    ),
                                  )
                                : Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          File(_shot!.path),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: GestureDetector(
                                          onTap: () =>
                                              setState(() => _shot = null),
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2A211B),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const OnboardingLineIcon(
                                              'x',
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              _shot == null
                                  ? 'Add a screenshot (optional)'
                                  : 'Screenshot added · tap to change',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8A7E70),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
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

// Design "I.camera" glyph in the Plus orange (for the screenshot tile).
const _kCameraSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="#F2623E" stroke-width="1.9" stroke-linecap="round" '
    'stroke-linejoin="round"><rect x="3" y="7" width="18" height="13" rx="4"/>'
    '<circle cx="12" cy="13.5" r="3.4"/>'
    '<circle cx="17" cy="10.5" r="1" fill="#F2623E" stroke="none"/></svg>';

/// Dashed rounded-rectangle border (for the screenshot tile in design 69).
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = math.min(dash, metric.length - dist);
        canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}
