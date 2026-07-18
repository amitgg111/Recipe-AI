import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cuisine_controller.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/screens/meal_plan/meal_planner_ui.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/cuisine_chip.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class AllCuisinesScreen extends StatefulWidget {
  const AllCuisinesScreen({super.key});

  @override
  State<AllCuisinesScreen> createState() => _AllCuisinesScreenState();
}

class _AllCuisinesScreenState extends State<AllCuisinesScreen> {
  final OnboardingController _c = Get.find<OnboardingController>();
  final CuisineController _cuisineC = CuisineController.to;
  final TextEditingController _searchC = TextEditingController();
  String _query = '';
  Set<String> _originalSelection = {};

  @override
  void initState() {
    super.initState();

    _originalSelection = Set<String>.from(_c.cuisines);

    if (_cuisineC.categories.isEmpty) {
      _cuisineC.fetchCuisines();
    }

    _searchC.addListener(() {
      setState(() => _query = _searchC.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  // Writes straight to the shared controller — CuisinesBody picks the change
  // up the moment you navigate back (no extra "save" step needed).
  void _toggle(String cuisine) {
    final selected = Set<String>.from(_c.cuisines);
    selected.remove(
      'A bit of everything',
    ); // picking a specific one overrides the shortcut
    if (selected.contains(cuisine)) {
      selected.remove(cuisine);
    } else {
      selected.add(cuisine);
    }
    _c.setCuisines(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // adjust if your const is named differently
      body: SafeArea(
        child: Obx(() {
          if (_cuisineC.isLoading.value && _cuisineC.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredSections = <MapEntry<String, List<String>>>[];
          for (final entry in _cuisineC.categories.entries) {
            final matches = _query.isEmpty
                ? entry.value
                : entry.value
                      .where((c) => c.toLowerCase().contains(_query))
                      .toList();
            if (matches.isNotEmpty) {
              filteredSections.add(MapEntry(entry.key, matches));
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).maybePop();
                        _c.setCuisines(_originalSelection);
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEDE3D2)),
                        ),
                        alignment: Alignment.center,
                        child: const OnboardingLineIcon(
                          'back',
                          size: 22,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'All cuisines'.tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 19,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchC,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search Cuisines'.tr,
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.textMedium,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,

                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filteredSections.isEmpty
                    ? Center(
                        child: Text(
                          'no_cuisines_found'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: filteredSections.length,
                        itemBuilder: (context, i) {
                          final section = filteredSections[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.key.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMedium,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Obx(
                                  () => Wrap(
                                    spacing: 9,
                                    runSpacing: 9,
                                    children: [
                                      for (final cuisine in section.value)
                                        CuisineChip(
                                          label: cuisine,
                                          isSelected: _c.cuisines.contains(
                                            cuisine,
                                          ),
                                          onTap: () => _toggle(cuisine),
                                          filledStyle: true,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: PrimaryButton(label: "Done", onTap: () => Get.back()),
              ),
            ],
          );
        }),
      ),
    );
  }
}
