import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeStepScreen extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepText;
  final String? timerLabel;
  final String? timerDuration;
  final VoidCallback? onClose;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onStartTimer;

  const CookModeStepScreen({
    super.key,
    this.currentStep = 3,
    this.totalSteps = 8,
    this.stepText = 'Add the chickpeas and coconut milk to the pan and stir gently to combine.',
    this.timerLabel = 'Start timer',
    this.timerDuration = '10:00',
    this.onClose,
    this.onNext,
    this.onBack,
    this.onStartTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildProgressBar(),
              const SizedBox(height: 32),
              _buildStepLabel(),
              const Spacer(),
              _buildStepText(),
              const SizedBox(height: 28),
              if (timerLabel != null && timerDuration != null)
                _buildTimerButton(),
              const Spacer(),
              _buildBottomNav(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose ?? () => Get.back(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
            ),
            child: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final progress = currentStep / totalSteps;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFEEE3D2),
        borderRadius: BorderRadius.circular(5),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel() {
    return Text(
      'step_of'.trParams({'current': '$currentStep', 'total': '$totalSteps'}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textMedium,
        letterSpacing: 0.04 * 13,
      ),
    );
  }

  Widget _buildStepText() {
    return Text(
      stepText,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.35,
      ),
    );
  }

  Widget _buildTimerButton() {
    return GestureDetector(
      onTap: onStartTimer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '$timerLabel · $timerDuration',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack ?? () => Get.back(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DECE), width: 1),
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'next_step'.tr,
            leadingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
