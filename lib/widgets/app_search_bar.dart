import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? cursorColor;
  final double borderRadius;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool showShadow;
  final bool showBorder;
  final bool showClearButton;
  final Duration animationDuration;
  final BoxShadow? shadow;
  final Border? border;
  final String? semanticsLabel;
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search recipes',
    this.hintStyle,
    this.textStyle,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.cursorColor,
    this.borderRadius = 18,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.margin = EdgeInsets.zero,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.search,
    this.inputFormatters,
    this.showShadow = true,
    this.showBorder = true,
    this.showClearButton = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.shadow,
    this.border,
    this.semanticsLabel,
    this.trailing,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleTextChange);
      if (_ownsController) _controller.dispose();
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = TextEditingController();
        _ownsController = true;
      }
      _hasText = _controller.text.isNotEmpty;
      _controller.addListener(_handleTextChange);
    }
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  Color get _bg => widget.backgroundColor ?? Colors.white;

  Color get _borderColor {
    if (!widget.showBorder) return Colors.transparent;
    if (_isFocused) {
      return widget.focusedBorderColor ??
          AppColors.primary.withValues(alpha: 0.35);
    }
    return widget.borderColor ?? const Color(0xFFEDEAE2);
  }

  BoxShadow get _shadow {
    if (!widget.showShadow) return const BoxShadow(color: Colors.transparent);
    if (widget.shadow != null) return widget.shadow!;
    if (_isFocused) {
      return BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 3),
      );
    }
    return BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textDark,
    );

    final defaultHintStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: const Color(0xFFB0ABA0),
    );

    final bool showClear =
        widget.showClearButton && _hasText && !widget.readOnly;

    return Semantics(
      label: widget.semanticsLabel ?? widget.hintText,
      textField: true,
      enabled: widget.enabled,
      child: Padding(
        padding: widget.margin,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
          height: widget.height,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border:
                widget.border ??
                (widget.showBorder
                    ? Border.all(
                        color: _borderColor,
                        width: _isFocused ? 1.5 : 1,
                      )
                    : null),
            boxShadow: [_shadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled && widget.readOnly ? widget.onTap : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: widget.readOnly ? null : Colors.transparent,
              highlightColor: widget.readOnly ? null : Colors.transparent,
              child: Padding(
                padding: widget.padding,
                child: Row(
                  children: [
                    // Prefix icon
                    widget.prefixIcon ??
                        Icon(
                          Icons.search_rounded,
                          size: 22,
                          color: _isFocused
                              ? AppColors.primary
                              : const Color(0xFFB7B2A6),
                        ),
                    const SizedBox(width: 12),

                    // TextField
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: widget.onChanged,
                        onSubmitted: widget.onSubmitted,
                        onTap: widget.readOnly ? null : widget.onTap,
                        enabled: widget.enabled,
                        readOnly: widget.readOnly,
                        autofocus: widget.autofocus,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        inputFormatters: widget.inputFormatters,
                        onTapOutside: (_) {
                          _focusNode.unfocus();
                        },
                        cursorColor: widget.cursorColor ?? AppColors.primary,
                        cursorRadius: const Radius.circular(2),
                        style: widget.textStyle ?? defaultTextStyle,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: widget.hintStyle ?? defaultHintStyle,
                          // The outer AnimatedContainer already draws the only
                          // border. Strip the inner field border in EVERY state
                          // (incl. focused/error) so it can't inherit the global
                          // InputDecorationTheme outline and create a double
                          // border. filled:false keeps the container's bg.
                          filled: false,
                          isDense: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    // Clear button
                    if (showClear)
                      GestureDetector(
                        onTap: _handleClear,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.textHint.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                      ),

                    // Suffix icon
                    if (widget.suffixIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: widget.suffixIcon,
                      ),

                    // Trailing widget
                    if (widget.trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: widget.trailing,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
