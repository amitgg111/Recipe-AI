import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

enum PrimaryButtonVariant { orange, purple }

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final PrimaryButtonVariant variant;

  /// Shows the animated white gloss sweep.
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
    _setupAnimations();
  }

  void _setupAnimations() {
    if (widget.enableSheen) {
      _sheenController = AnimationController(
        vsync: this,
        // Slower sweep
        duration: const Duration(milliseconds: 2600),
      );

      _sheenAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _sheenController!, curve: Curves.easeInOut),
      );

      _startSheen();
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

  Future<void> _startSheen() async {
    while (mounted && widget.enableSheen) {
      await _sheenController?.forward(from: 0);

      if (!mounted || !widget.enableSheen) return;

      // Pause before next sweep
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  @override
  void didUpdateWidget(covariant PrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enableSheen != widget.enableSheen) {
      _sheenController?.dispose();
      _sheenController = null;
      _sheenAnimation = null;

      if (widget.enableSheen) {
        _sheenController = AnimationController(
          vsync: this,
          // IMPORTANT: same slow duration here too
          duration: const Duration(milliseconds: 2600),
        );

        _sheenAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
          CurvedAnimation(parent: _sheenController!, curve: Curves.easeInOut),
        );

        _startSheen();
      }
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
          onTap: widget.isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onPressed?.call();
                },
          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Button content
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

                // Animated white gloss sweep
                if (widget.enableSheen && _sheenAnimation != null)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sheenAnimation!,
                      builder: (context, child) {
                        final position = _sheenAnimation!.value;

                        return FractionalTranslation(
                          translation: Offset(position, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.35,
                              heightFactor: 1.4,
                              child: Transform.rotate(
                                angle: 0.0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.enableBob && _bobAnimation != null) {
      button = AnimatedBuilder(
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
