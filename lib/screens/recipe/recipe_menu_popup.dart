import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class RecipeMenuPopup {
  static void show(
    BuildContext context, {
    required RelativeRect position,
  }) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      barrierDismissible: true,
      barrierLabel: 'RecipeMenu',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: _RecipeMenuContent(position: position),
        );
      },
    );
  }
}

class _RecipeMenuContent extends StatefulWidget {
  final RelativeRect position;

  const _RecipeMenuContent({required this.position});

  @override
  State<_RecipeMenuContent> createState() => _RecipeMenuContentState();
}

class _RecipeMenuContentState extends State<_RecipeMenuContent> {
  bool _isPublic = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss on tap
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Popup card positioned from top-right
        Positioned(
          top: widget.position.top,
          right: widget.position.right,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Triangle pointer
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        left: BorderSide(color: const Color(0xFFEFE6D6)),
                        top: BorderSide(color: const Color(0xFFEFE6D6)),
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 222,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEFE6D6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Public recipe toggle
                        _buildToggleItem(
                          icon: Icons.language,
                          label: 'Public recipe',
                          value: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v),
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.share_outlined,
                          label: 'Share recipe link',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          label: 'Export PDF',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildMenuItem(
                          icon: Icons.print_outlined,
                          label: 'Print recipe',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          label: 'Delete recipe',
                          isDestructive: true,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 26,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.green,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD5D0C8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.red : AppColors.textDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.divider,
    );
  }
}
