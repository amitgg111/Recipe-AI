import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// Emoji-flag lookup shared between the onboarding cuisine picker and the
/// "All cuisines" screen. Covers every cuisine visible across both screens;
/// anything not listed falls through to keyword matching, then a plate emoji.
const Map<String, String> kFlagByCuisine = {
  // South Asia
  'Indian': '🇮🇳', 'North Indian': '🇮🇳', 'South Indian': '🇮🇳',
  'Pakistani': '🇵🇰', 'Bangladeshi': '🇧🇩', 'Sri Lankan': '🇱🇰',
  'Nepali': '🇳🇵', 'Afghan': '🇦🇫',
  // East Asia
  'Chinese': '🇨🇳', 'Sichuan': '🇨🇳', 'Cantonese': '🇨🇳',
  'Japanese': '🇯🇵', 'Korean': '🇰🇷', 'Taiwanese': '🇹🇼',
  'Mongolian': '🇲🇳', 'Tibetan': '🏔️',
  // Southeast Asia
  'Thai': '🇹🇭', 'Vietnamese': '🇻🇳', 'Filipino': '🇵🇭',
  'Indonesian': '🇮🇩', 'Malaysian': '🇲🇾', 'Singaporean': '🇸🇬',
  'Cambodian': '🇰🇭', 'Burmese': '🇲🇲', 'Laotian': '🇱🇦',

  // Dietary Styles
  'Vegetarian': '🌱',
  'Vegan': '🥬', 'Halal': '🕌',
  'Kosher': '✡️',
  'Fusion': '🍜',
  'Continental': '🥂',
  'BBQ / Grill': '🔥',
  'Seafood': '🦞',
  'Street Food': '🌮',
  // Middle East & Central Asia
  'Lebanese': '🇱🇧', 'Turkish': '🇹🇷', 'Persian': '🇮🇷',
  'Israeli': '🇮🇱', 'Syrian': '🇸🇾', 'Iraqi': '🇮🇶',
  'Arabian': '🇸🇦', 'Yemeni': '🇾🇪', 'Uzbek': '🇺🇿',
  'Georgian': '🇬🇪', 'Armenian': '🇦🇲',
  // Mediterranean & S. Europe
  'Italian': '🇮🇹', 'Greek': '🇬🇷', 'Spanish': '🇪🇸',
  'Portuguese': '🇵🇹', 'French': '🇫🇷', 'Cypriot': '🇨🇾', 'Maltese': '🇲🇹',
  // N. Central & E. Europe
  'German': '🇩🇪', 'British': '🇬🇧', 'Irish': '🇮🇪', 'Dutch': '🇳🇱',
  'Scandinavian': '🇸🇪', 'Polish': '🇵🇱', 'Russian': '🇷🇺',
  'Ukrainian': '🇺🇦',
  'Hungarian': '🇭🇺',
  'Czech': '🇨🇿',
  'Romanian': '🇷🇴',
  'Balkan': '🇧🇦',
  // Africa
  'Moroccan': '🇲🇦', 'Egyptian': '🇪🇬', 'Ethiopian': '🇪🇹',
  'Nigerian': '🇳🇬', 'West African': '🌍', 'North African': '🌍',
  'South African': '🇿🇦', 'Kenyan': '🇰🇪', 'Ghanaian': '🇬🇭',
  // The Americas
  'American': '🇺🇸', 'Southern / Soul': '🇺🇸', 'Cajun & Creole': '🇺🇸',
  'Tex-Mex': '🇺🇸', 'Mexican': '🇲🇽', 'Caribbean': '🏝️',
  'Jamaican': '🇯🇲', 'Cuban': '🇨🇺', 'Brazilian': '🇧🇷',
  'Peruvian': '🇵🇪',
  'Argentine': '🇦🇷',
  'Colombian': '🇨🇴',
  'Venezuelan': '🇻🇪',
  // Oceania
  'Australian': '🇦🇺', 'New Zealand': '🇳🇿', 'Hawaiian': '🌺',
  'Pacific Islander': '🏝️',
  // Meta option (onboarding-only shortcut)
  'A bit of everything': '🌍',
};

/// Exact match first; falls back to substring keyword matching (so a
/// Firestore entry like "Indian Street Food" still resolves to 🇮🇳), then
/// a generic plate emoji if nothing matches.
String flagForCuisine(String cuisine) {
  if (kFlagByCuisine.containsKey(cuisine)) return kFlagByCuisine[cuisine]!;
  final lower = cuisine.toLowerCase();
  for (final entry in kFlagByCuisine.entries) {
    if (lower.contains(entry.key.toLowerCase())) return entry.value;
  }
  return '🍽️';
}

/// Shared selectable chip.
/// [filledStyle]=false → icon-square + border style (onboarding "popular" grid).
/// [filledStyle]=true  → solid-fill pill, no icon box (All cuisines screen).
class CuisineChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool fullWidth;
  final bool filledStyle;

  const CuisineChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.fullWidth = false,
    this.filledStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (filledStyle
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.07))
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected && !filledStyle ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!filledStyle) ...[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,

                decoration: BoxDecoration(
                  // color: AppColors.textDark.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  flagForCuisine(label),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Text(flagForCuisine(label), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected && filledStyle
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: child) : child;
  }
}
