import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
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
            // Header image grid: height 230, no safe area padding
            _buildHeroImages(),
            // Content: padding 4px 26px 26px, margin-top -8px
            Transform.translate(
              offset: const Offset(0, -8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 4, 26, 26),
                child: Column(
                  children: [
                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.18,
                          letterSpacing: -0.52,
                        ),
                        children: [
                          const TextSpan(text: 'Choose your '),
                          TextSpan(
                            text: 'trial experience',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.18,
                              letterSpacing: -0.52,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Trial option 1: FREE 7 day (selected)
                    _buildPlanOption(
                      index: 0,
                      price: 'FREE',
                      period: '7 day trial',
                    ),
                    const SizedBox(height: 12),
                    // Trial option 2: 99.00 30 day
                    _buildPlanOption(
                      index: 1,
                      price: '₹99.00',
                      period: '30 day trial',
                    ),
                    const SizedBox(height: 16),
                    // Reminder toggle
                    _buildRemindToggle(),
                    const SizedBox(height: 16),
                    // View all plans link
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'View all plans',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMedium,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 8),
                    // No payment row
                    _buildNoPaymentRow(),
                    const SizedBox(height: 14),
                    // Button
                    PrimaryButton.purple(
                      label: 'Redeem 7 days for ₹0.00',
                      onPressed: () =>
                          Get.offAll(() => const CreateAccountScreen()),
                    ),
                    const SizedBox(height: 10),
                    // Disclaimer
                    Text(
                      '7 days free, then ₹1,700.00 / year · Cancel anytime',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLighter,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          // 3-column grid with 5px gap, opacity 0.96
          Opacity(
            opacity: 0.96,
            child: Row(
              children: [
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.orange.shade200,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.green.shade200,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _HeroImage(
                    url:
                        'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=240&q=80&auto=format&fit=crop',
                    fallback: Colors.red.shade200,
                  ),
                ),
              ],
            ),
          ),
          // Gradient overlay: linear-gradient 180deg, transparent 40% -> background 100%
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFBF4EA).withValues(alpha: 0),
                    const Color(0xFFFBF4EA),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          // Close button: absolute top 14px, right 18px
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
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          // "Healthy" tag: top 64, left 24, rotate -6deg
          Positioned(
            top: 64,
            left: 24,
            child: Transform.rotate(
              angle: -6 * 3.14159265 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldStar,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'Healthy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A4410),
                  ),
                ),
              ),
            ),
          ),
          // "Fall recipes" tag: top 48, right 30, rotate 7deg
          Positioned(
            top: 48,
            right: 30,
            child: Transform.rotate(
              angle: 7 * 3.14159265 / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.starOrange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'Fall recipes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5A3410),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required int index,
    required String price,
    required String period,
  }) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                    spreadRadius: -16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  period,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.unselectedBorder,
                    width: 2,
                  ),
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
        color: AppColors.primaryShadow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Remind me before my trial ends',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _remindMe = !_remindMe),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 27,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _remindMe
                    ? AppColors.primary
                    : AppColors.unselectedBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: _remindMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
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
        // 10M+ stat
        Column(
          children: [
            Text(
              '10M+',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Happy cooks',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        // Divider: 1px wide, 28px tall
        Container(
          width: 1,
          height: 28,
          color: AppColors.unselectedBorder,
          margin: const EdgeInsets.symmetric(horizontal: 22),
        ),
        // Stars + rating
        Column(
          children: [
            Row(
              children: List.generate(
                5,
                (_) =>
                    const Icon(Icons.star, color: AppColors.goldStar, size: 14),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '4.8 rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoPaymentRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 7),
          Text(
            'No payment now',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String url;
  final Color fallback;

  const _HeroImage({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: fallback);
      },
      errorBuilder: (context, error, stack) => Container(color: fallback),
    );
  }
}
