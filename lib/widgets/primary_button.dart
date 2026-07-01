import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

enum PrimaryButtonVariant { orange, purple }

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final PrimaryButtonVariant variant;
  final bool enableSheen;
  final bool enableBob;
  final bool isLoading;
  final double? width;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.variant = PrimaryButtonVariant.orange,
    this.enableSheen = false,
    this.enableBob = false,
    this.isLoading = false,
    this.width,
    this.height,
  });

  const PrimaryButton.purple({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.enableSheen = false,
    this.enableBob = false,
    this.isLoading = false,
    this.width,
    this.height,
  }) : variant = PrimaryButtonVariant.purple;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with TickerProviderStateMixin {
  AnimationController? _sheenController;
  AnimationController? _bobController;
  Animation<double>? _sheenAnimation;
  Animation<double>? _bobAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.enableSheen) {
      _sheenController = AnimationController(
        duration: const Duration(milliseconds: 1800),
        vsync: this,
      )..repeat(period: const Duration(milliseconds: 2500));
      _sheenAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _sheenController!, curve: Curves.easeInOut),
      );
    }
    if (widget.enableBob) {
      _bobController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat(reverse: true);
      _bobAnimation = Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: _bobController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _sheenController?.dispose();
    _bobController?.dispose();
    super.dispose();
  }

  Color get _baseColor => widget.variant == PrimaryButtonVariant.purple
      ? AppColors.purple
      : AppColors.primary;

  Color get _shadowColor => widget.variant == PrimaryButtonVariant.purple
      ? AppColors.purpleShadow
      : AppColors.primaryShadow;

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? AppDimensions.buttonHeight,
      decoration: BoxDecoration(
        color: _baseColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 30,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            child: Stack(
              children: [
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.leadingIcon != null) ...[
                              widget.leadingIcon!,
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: AppTextStyles.buttonLabel,
                            ),
                          ],
                        ),
                ),
                if (widget.enableSheen && _sheenAnimation != null)
                  _AnimatedBuilder(
                    animation: _sheenAnimation!,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.15),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: [
                                _sheenAnimation!.value - 0.3,
                                _sheenAnimation!.value,
                                _sheenAnimation!.value + 0.3,
                              ].map((s) => s.clamp(0.0, 1.0)).toList(),
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.enableBob && _bobAnimation != null) {
      button = _AnimatedBuilder(
        animation: _bobAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bobAnimation!.value),
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
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
