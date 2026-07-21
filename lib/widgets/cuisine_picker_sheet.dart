import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/Controllers/cuisine_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';

class _S {
  static TextStyle f(double size, FontWeight weight, Color color, {double? h}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: h,
    );
  }
}

/// Cuisine picker bottom sheet — grouped by category (African, Dietary
/// styles, etc.), search bar on top, single or multi-select via [multiSelect].
///
/// Usage:
/// ```dart
/// final picked = await CuisinePickerSheet.open(context); // single
/// final pickedList = await CuisinePickerSheet.open(context, multiSelect: true); // multi
/// ```
class CuisinePickerSheet extends StatefulWidget {
  final bool multiSelect;
  final Set<String> initialSelected;

  const CuisinePickerSheet({
    super.key,
    this.multiSelect = false,
    this.initialSelected = const {},
  });

  /// Opens the sheet and returns the selection (or null if dismissed).
  /// - single-select: returns `String?`
  /// - multi-select: returns `Set<String>?`
  static Future<T?> open<T>(
    BuildContext context, {
    bool multiSelect = false,
    Set<String> initialSelected = const {},
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CuisinePickerSheet(
        multiSelect: multiSelect,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<CuisinePickerSheet> createState() => _CuisinePickerSheetState();
}

class _CuisinePickerSheetState extends State<CuisinePickerSheet> {
  String _search = '';
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelected};
    CuisineController.to.fetchCuisines();
  }

  void _toggle(String cuisine) async {
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(cuisine)) {
          _selected.remove(cuisine);
        } else {
          _selected.add(cuisine);
        }
      });
    } else {
      setState(() {
        _selected
          ..clear()
          ..add(cuisine);
      });
      CuisineController.to.selectedCuisine.value = cuisine;

      await Future.delayed(const Duration(milliseconds: 180));

      if (mounted) {
        Navigator.pop(context, cuisine);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E0D2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Cuisine',
                    style: _S.f(19, FontWeight.w800, AppColors.textDark),
                  ),
                ),
                if (widget.multiSelect)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _selected),
                    child: Text(
                      'Done',
                      style: _S.f(14, FontWeight.w700, AppColors.primary),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => Get.back(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1EA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF8A7E70),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppSearchBar(
              hintText: 'Search cuisines...',
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (CuisineController.to.isLoading.value &&
                  CuisineController.to.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final categories = CuisineController.to.categories;
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'No cuisines found',
                    style: _S.f(14, FontWeight.w500, AppColors.textHint),
                  ),
                );
              }

              // Filter by search — drop empty categories after filtering.
              final filtered = <String, List<String>>{};
              categories.forEach((cat, list) {
                final matches = _search.isEmpty
                    ? list
                    : list
                          .where((c) => c.toLowerCase().contains(_search))
                          .toList();
                if (matches.isNotEmpty) filtered[cat] = matches;
              });

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No matches',
                    style: _S.f(14, FontWeight.w500, AppColors.textHint),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  for (final entry in filtered.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 8),
                      child: Text(
                        entry.key,
                        style: _S.f(
                          12.5,
                          FontWeight.w800,
                          AppColors.textMedium,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((cuisine) {
                        final sel = _selected.contains(cuisine);
                        return GestureDetector(
                          onTap: () => _toggle(cuisine),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF7C4DFF),
                                        Color(0xFF5E35B1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: sel ? null : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF6C4EFF)
                                    : const Color(0xFFE8E2D8),
                                width: 1.2,
                              ),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7C4DFF,
                                        ).withOpacity(.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              cuisine,
                              style: _S.f(
                                13,
                                FontWeight.w700,
                                sel ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
