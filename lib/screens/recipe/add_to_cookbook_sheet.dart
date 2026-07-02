import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class AddToCookbookSheet extends StatefulWidget {
  const AddToCookbookSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddToCookbookSheet(),
    );
  }

  @override
  State<AddToCookbookSheet> createState() => _AddToCookbookSheetState();
}

class _AddToCookbookSheetState extends State<AddToCookbookSheet> {
  final Set<int> _selected = {0}; // First cookbook selected by default

  final List<_CookbookItem> _cookbooks = [
    _CookbookItem('Weeknight Dinners', 12),
    _CookbookItem('Fresh & Green', 8),
    _CookbookItem('Comfort Food', 15),
    _CookbookItem('Quick Lunch', 6),
    _CookbookItem('Desserts', 9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: 8),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add to cookbook', style: AppTextStyles.listTitle),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F1EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cookbook list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _cookbooks.length + 1, // +1 for "New cookbook"
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                if (index == _cookbooks.length) {
                  return _buildNewCookbookRow();
                }
                return _buildCookbookItem(index, _cookbooks[index]);
              },
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context, _selected.toList()),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildCookbookItem(int index, _CookbookItem cookbook) {
    final isSelected = _selected.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selected.remove(index);
          } else {
            _selected.add(index);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF6F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Thumbnail grid (2x2)
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.background,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(4, (i) {
                    final colors = [
                      const Color(0xFFE8D5B8),
                      const Color(0xFFD4C4A8),
                      const Color(0xFFC7B89A),
                      const Color(0xFFDBC8AB),
                    ];
                    return Container(color: colors[i]);
                  }),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cookbook.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${cookbook.count} recipes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            // Check circle
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFE2D8C7),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCookbookRow() {
    return GestureDetector(
      onTap: () {
        // Handle new cookbook creation
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Dashed circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Text(
              'New cookbook',
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
}

class _CookbookItem {
  final String name;
  final int count;
  _CookbookItem(this.name, this.count);
}
