import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cuisine_controller.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/cuisine_chip.dart';
import 'all_cuisines_screen.dart'; // adjust path to wherever you place it

class CuisinesBody extends StatefulWidget {
  final ValueChanged<bool>? onValidityChanged;
  const CuisinesBody({super.key, this.onValidityChanged});

  @override
  State<CuisinesBody> createState() => _CuisinesBodyState();
}

class _CuisinesBodyState extends State<CuisinesBody> {
  final OnboardingController _c = Get.find<OnboardingController>();
  final CuisineController _cuisineC = CuisineController.to;

  late Set<String> _selectedCuisines;
  static const String _everythingOption = 'A bit of everything';

  @override
  void initState() {
    super.initState();
    _selectedCuisines = Set<String>.from(_c.cuisines);
    if (_cuisineC.categories.isEmpty) {
      _cuisineC.fetchCuisines();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValidityChanged?.call(_selectedCuisines.isNotEmpty);
    });
  }

  void _toggle(String cuisine) {
    setState(() {
      if (cuisine == _everythingOption) {
        _selectedCuisines
          ..clear()
          ..add(_everythingOption);
      } else {
        _selectedCuisines.remove(_everythingOption);
        if (_selectedCuisines.contains(cuisine)) {
          _selectedCuisines.remove(cuisine);
        } else {
          _selectedCuisines.add(cuisine);
        }
      }
    });
    _c.setCuisines(_selectedCuisines);
    widget.onValidityChanged?.call(_selectedCuisines.isNotEmpty);
  }

  Future<void> _openAllCuisines() async {
    await Get.to(() => const AllCuisinesScreen());
    // Pull back whatever changed on the full-list screen.
    setState(() => _selectedCuisines = Set<String>.from(_c.cuisines));
    widget.onValidityChanged?.call(_selectedCuisines.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_cuisineC.isLoading.value && _cuisineC.categories.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final popular =
          _cuisineC.categories['popular'] ??
          _cuisineC.allCuisines.take(9).toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'What food do you cook most?'.tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.50,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "We'll tailor recipes & AI suggestions to your taste. Pick any."
                  .tr,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 11,
                      runSpacing: 11,
                      children: [
                        for (final cuisine in popular)
                          SizedBox(
                            width:
                                (MediaQuery.of(context).size.width - 52 - 11) /
                                2,
                            child: CuisineChip(
                              label: cuisine,
                              isSelected: _selectedCuisines.contains(cuisine),
                              onTap: () => _toggle(cuisine),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    CuisineChip(
                      label: _everythingOption,
                      isSelected: _selectedCuisines.contains(_everythingOption),
                      onTap: () => _toggle(_everythingOption),
                      fullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _openAllCuisines,

                        child: Text(
                          'See All Cuisines'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
