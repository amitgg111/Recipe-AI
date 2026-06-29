import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/widgets/primary_button.dart';
import 'package:recipe_ai/screens/auth/create_account_screen.dart';

class TrialChooserScreen extends StatefulWidget {
  const TrialChooserScreen({super.key});

  @override
  State<TrialChooserScreen> createState() => _TrialChooserScreenState();
}

class _TrialChooserScreenState extends State<TrialChooserScreen> {
  int _selectedPlan = 0;
  bool _remindMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroImages(),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 4, 26, 26),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Choose your ',
                      children: [
                        TextSpan(
                          text: 'trial experience',
                          style: TextStyle(color: AppColors.purple),
                        ),
                      ],
                    ),
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 26),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  _buildPlanOption(0, 'FREE', '7 day trial', null),
                  const SizedBox(height: 12),
                  _buildPlanOption(1, '₹99.00', '30 day trial', null),
                  const SizedBox(height: 16),
                  _buildRemindToggle(),
                  const SizedBox(height: 16),
                  Text(
                    'View all plans',
                    style: AppTextStyles.link.copyWith(
                      color: AppColors.textMedium,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildStatsRow(),
                  const SizedBox(height: 8),
                  _buildNoPaymentRow(),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Redeem 7 days for ₹0.00',
                    onPressed: () => Get.offAll(() => const CreateAccountScreen()),
                    variant: PrimaryButtonVariant.purple,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '7 days free, then ₹1,700.00 / year · Cancel anytime',
                    style: AppTextStyles.trialPrice,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImages() {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(child: Container(color: const Color(0xFFE8C9A0))),
              const SizedBox(width: 5),
              Expanded(child: Container(color: const Color(0xFFD4A574))),
              const SizedBox(width: 5),
              Expanded(child: Container(color: const Color(0xFFC19660))),
            ],
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 18,
            child: GestureDetector(
              onTap: () => Get.offAll(() => const CreateAccountScreen()),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.close, size: 20, color: AppColors.textDark),
              ),
            ),
          ),
          Positioned(
            top: 64,
            left: 24,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C84C),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text('Healthy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF5A4410))),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 30,
            child: Transform.rotate(
              angle: 0.12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.starOrange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text('Fall recipes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF5A3410))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(int index, String price, String period, String? badge) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.purple : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 26, offset: const Offset(0, 12), spreadRadius: -16)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price, style: AppTextStyles.listTitle.copyWith(fontSize: 17)),
                const SizedBox(height: 1),
                Text(period, style: TextStyle(fontSize: 13, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
              ],
            ),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.unselectedBorder, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.purpleBgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Remind me before my trial ends',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          GestureDetector(
            onTap: () => setState(() => _remindMe = !_remindMe),
            child: Container(
              width: 46,
              height: 27,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _remindMe ? AppColors.purple : AppColors.unselectedBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: _remindMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text('10M+', style: AppTextStyles.statMedium),
            const SizedBox(height: 2),
            Text('Happy cooks', style: TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          ],
        ),
        Container(width: 1, height: 28, color: AppColors.unselectedBorder, margin: const EdgeInsets.symmetric(horizontal: 22)),
        Column(
          children: [
            Row(
              children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: AppColors.goldStar, size: 16)),
            ),
            const SizedBox(height: 2),
            Text('4.8 rating', style: TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildNoPaymentRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check, color: AppColors.green, size: 20),
        const SizedBox(width: 7),
        Text('No payment now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}
