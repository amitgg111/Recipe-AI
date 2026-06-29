import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.menu_book_rounded, label: 'Cookbooks'),
    _NavItem(icon: Icons.explore_outlined, label: 'Discover'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Meal Plan'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Groceries'),
    _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: AppDimensions.bottomNavHeight,
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
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _NavTab extends StatelessWidget {
  final IconData icon;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFCE3DB) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconMd,
              color: isActive ? AppColors.primary : AppColors.tabInactive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
