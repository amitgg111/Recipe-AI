import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/theme/app_colors.dart';

/// Shared building blocks for the Settings / More section so every screen
/// matches the HTML design (white cards, #EFE6D6 borders, radius 18, section
/// headers 12px w800 letter-spaced, rows with 14/15 padding + divider).
class SettingsUi {
  SettingsUi._();

  static const Color rowIcon = AppColors.textBodyDark; // #5A5147
  static const Color chevron = AppColors.iconLight; // #C7BCAC
  static const Color sectionLabel = AppColors.textHint; // #A89F90

  /// Standard back-button page header used on all sub-screens.
  static Widget header(
    String title, {
    Widget? trailing,
    VoidCallback? onBack,
    IconData backIcon = Icons.arrow_back,
  }) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _squareButton(
            icon: backIcon,
            iconWidget: backIcon == Icons.arrow_back
                ? const OnboardingLineIcon(
                    'back',
                    size: 20,
                    color: AppColors.textDark,
                  )
                : null,
            onTap: onBack ?? () => Get.back(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static Widget _squareButton({
    required IconData icon,
    Widget? iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFEFEDE6)),
        ),
        child: iconWidget ?? Icon(icon, size: 20, color: AppColors.textDark),
      ),
    );
  }

  static Widget squareIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) => _squareButton(icon: icon, onTap: onTap);

  /// Uppercase section label (12px w800, letter-spacing .06em).
  static Widget label(String text, {EdgeInsets? padding}) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(4, 22, 4, 9),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: sectionLabel,
          letterSpacing: 0.72,
        ),
      ),
    );
  }

  /// White rounded card that hosts a column of [rows] with dividers between.
  static Widget card({required List<Widget> rows}) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  /// A tappable settings row: leading icon, label, optional trailing + chevron.
  static Widget row({
    IconData? icon,
    Widget? leadingIcon,
    required String label,
    String? subtitle,
    Widget? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(width: 13),
            ] else if (icon != null) ...[
              Icon(icon, size: 21, color: rowIcon),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (showChevron) ...[
              const SizedBox(width: 8),
              const OnboardingLineIcon('chevR', color: chevron, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

/// Circular profile avatar. Reuses ProfileController.imagePath (local cache)
/// with a FirebaseAuth photoURL fallback and a person-icon placeholder.
class ProfileAvatar extends StatelessWidget {
  final double size;

  const ProfileAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Obx(() {
      final path = controller.imagePath.value.trim();

      // --------------------------------------------------------
      // LOCAL IMAGE = INSTANT
      // --------------------------------------------------------

      if (path.isNotEmpty && !path.startsWith('http')) {
        final file = controller.profileFile;

        if (file != null) {
          return ClipOval(
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover, // 👈 FIX: contain -> cover

              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
          );
        }
      }

      // --------------------------------------------------------
      // NETWORK IMAGE
      // --------------------------------------------------------

      if (path.isNotEmpty && path.startsWith('http')) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: path,
            width: size,
            height: size,
            fit: BoxFit.cover,

            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          ),
        );
      }

      return ClipOval(child: _placeholder());
    });
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.shimmerBase,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, size: size * 0.5, color: Colors.white),
    );
  }
}

/// HTML-style pill toggle switch (46x27, orange when on).
class SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 46,
        height: 27,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : const Color(0xFFE2D8C7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}
