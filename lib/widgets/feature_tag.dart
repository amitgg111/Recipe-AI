import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class FeatureTag extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color iconBackground;
  final VoidCallback? onTap;
  final bool enableFloat;

  const FeatureTag({
    super.key,
    required this.label,
    required this.icon,
    this.iconBackground = AppColors.background,
    this.onTap,
    this.enableFloat = false,
  });

  @override
  State<FeatureTag> createState() => _FeatureTagState();
}

class _FeatureTagState extends State<FeatureTag>
    with SingleTickerProviderStateMixin {
  AnimationController? _floatController;
  Animation<double>? _floatAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.enableFloat) {
      _floatController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      )..repeat(reverse: true);
      _floatAnimation = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _floatController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _floatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tag = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.iconLg,
              height: AppDimensions.iconLg,
              decoration: BoxDecoration(
                color: widget.iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: widget.icon),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: AppTextStyles.chipLabel.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.enableFloat && _floatAnimation != null) {
      return _AnimatedBuilder(
        animation: _floatAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation!.value),
            child: child,
          );
        },
        child: tag,
      );
    }

    return tag;
  }
}

class _AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimatedBuilder({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
