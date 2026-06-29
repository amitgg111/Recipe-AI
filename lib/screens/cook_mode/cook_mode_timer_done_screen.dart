import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeTimerDoneScreen extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onClose;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const CookModeTimerDoneScreen({
    super.key,
    this.currentStep = 3,
    this.totalSteps = 8,
    this.onClose,
    this.onContinue,
    this.onBack,
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
              const Spacer(flex: 3),
              _buildCheckmarkCircle(),
              const SizedBox(height: 28),
              Text(
                'Timer complete!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your timer has finished. Ready to continue?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              PrimaryButton(
                label: 'Continue cooking',
                onPressed: onContinue,
              ),
              const SizedBox(height: 16),
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
            child: const Icon(Icons.close, size: 20, color: AppColors.textDark),
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

  Widget _buildCheckmarkCircle() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.green,
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        size: 64,
        color: Colors.white,
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
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Next step',
            leadingIcon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}
