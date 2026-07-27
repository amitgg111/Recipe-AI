import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';
import 'onboarding_line_icon.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Exact HTML `navTab` icon set: book / compass / cal / cart / dots.
  // Labels are translation KEYS (resolved with `.tr` at render) so the list can
  // stay const while still switching language live.
  static const _items = [
    _NavItem(icon: 'book', label: 'cookbooks'),
    _NavItem(icon: 'compass', label: 'discover'),
    _NavItem(icon: 'cal', label: 'meal_plan'),
    _NavItem(icon: 'cart', label: 'groceries'),
    _NavItem(icon: 'dots', label: 'more'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: AppDimensions.bottomNavHeight +
              MediaQuery.of(context).padding.bottom,
          decoration: const BoxDecoration(
            color: AppColors.bottomNavBg,
            border: Border(
              top: BorderSide(color: AppColors.bottomNavBorder),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              return _NavTab(
                icon: item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _NavTab extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 50×30 icon pill (pink bg only when active), matching the HTML.
          Container(
            width: 50,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFCE3DB) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: OnboardingLineIcon(
              icon,
              color: isActive ? AppColors.primary : AppColors.tabInactive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.tr,
            style: isActive
                ? AppTextStyles.bottomNavActive.copyWith(
                    color: AppColors.primary,
                  )
                : AppTextStyles.bottomNavInactive.copyWith(
                    color: AppColors.tabInactive,
                  ),
          ),
        ],
      ),
    );
  }
}
