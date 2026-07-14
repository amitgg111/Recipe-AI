import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class SetStepTimerSheet extends StatefulWidget {
  final int stepNumber;

  const SetStepTimerSheet({super.key, required this.stepNumber});

  static void show(BuildContext context, {required int stepNumber}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetStepTimerSheet(stepNumber: stepNumber),
    );
  }

  @override
  State<SetStepTimerSheet> createState() => _SetStepTimerSheetState();
}

class _SetStepTimerSheetState extends State<SetStepTimerSheet> {
  int _minutes = 15;
  int _seconds = 0;
  int _selectedQuickPick = 3; // index of 15 min

  final List<_QuickPick> _quickPicks = [
    _QuickPick(1),
    _QuickPick(5),
    _QuickPick(10),
    _QuickPick(15),
    _QuickPick(30),
  ];

  String get _formattedTime {
    final m = _minutes.toString().padLeft(2, '0');
    final s = _seconds.toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text('step_timer'.tr, style: AppTextStyles.listTitle),
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
          const SizedBox(height: 8),
          Text(
            '${'adds_tappable_timer'.tr}'
            '${'step_number'.trParams({'number': '${widget.stepNumber}'})}'
            '${'while_cooking'.tr}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 28),
          // Large MM:SS display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minutes box
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 88,
                  height: 84,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3EF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _minutes.toString().padLeft(2, '0'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  ':',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              // Seconds box
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 88,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE7DECE),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _seconds.toString().padLeft(2, '0'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick pick chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickPicks.asMap().entries.map((entry) {
              final isSelected = entry.key == _selectedQuickPick;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedQuickPick = entry.key;
                      _minutes = entry.value.minutes;
                      _seconds = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      'minutes_short'.trParams({
                        'count': '${entry.value.minutes}',
                      }),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'add_timer_time'.trParams({'time': _formattedTime}),
            onPressed: () => Navigator.pop(context, _formattedTime),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _QuickPick {
  final int minutes;
  _QuickPick(this.minutes);
}
