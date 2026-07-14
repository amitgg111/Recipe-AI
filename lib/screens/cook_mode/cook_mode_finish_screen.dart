import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/primary_button.dart';

class CookModeFinishScreen extends StatefulWidget {
  final String recipeName;
  final String? imageUrl;
  final int totalSteps;
  final int totalMinutes;
  final VoidCallback? onClose;
  final VoidCallback? onSaveFinish;
  final VoidCallback? onShare;

  const CookModeFinishScreen({
    super.key,
    this.recipeName = 'Coconut Chickpea Curry',
    this.imageUrl,
    this.totalSteps = 5,
    this.totalMinutes = 35,
    this.onClose,
    this.onSaveFinish,
    this.onShare,
  });

  @override
  State<CookModeFinishScreen> createState() => _CookModeFinishScreenState();
}

class _CookModeFinishScreenState extends State<CookModeFinishScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _confettiControllers;
  // Fixed float phase (0..1) per piece so their bobbing is staggered but each
  // loops seamlessly (sin returns to 0 at the wrap).
  static const List<double> _confettiPhase = [0.0, 0.25, 0.5, 0.75];
  int _selectedRating = 4;

  final List<_ConfettiPiece> _confettiPieces = [
    const _ConfettiPiece(
      color: AppColors.primary,
      size: 11,
      rotation: 20,
      shape: _ConfettiShape.square,
      left: 0.08,
      top: 0.12,
      duration: Duration(milliseconds: 3800),
    ),
    const _ConfettiPiece(
      color: AppColors.green,
      size: 9,
      rotation: 0,
      shape: _ConfettiShape.circle,
      left: 0.85,
      top: 0.08,
      duration: Duration(milliseconds: 4200),
    ),
    const _ConfettiPiece(
      color: Color(0xFFE0481F),
      size: 8,
      rotation: 45,
      shape: _ConfettiShape.square,
      left: 0.92,
      top: 0.22,
      duration: Duration(milliseconds: 3400),
    ),
    const _ConfettiPiece(
      color: AppColors.primary,
      size: 12,
      rotation: -15,
      shape: _ConfettiShape.square,
      left: 0.12,
      top: 0.25,
      duration: Duration(milliseconds: 4400),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // One long-lived controller per piece, each running continuously (linear)
    // so its full 0..1 cycle drives a seamless sin float that connects the last
    // frame to the first with no restart or jump.
    _confettiControllers = _confettiPieces.map((piece) {
      return AnimationController(vsync: this, duration: piece.duration)
        ..repeat();
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _confettiControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti pieces
            ..._buildConfetti(context),
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildCloseButton(),
                  const SizedBox(height: 48),
                  _buildHeroImage(),
                  const SizedBox(height: 20),
                  _buildStatsBadge(),
                  const SizedBox(height: 20),
                  _buildTitle(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const SizedBox(height: 28),
                  _buildRatingCard(),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'save_and_finish'.tr,
                    onPressed: widget.onSaveFinish,
                  ),
                  const SizedBox(height: 12),
                  _buildShareButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConfetti(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return _confettiPieces.asMap().entries.map((entry) {
      final index = entry.key;
      final piece = entry.value;

      return AnimatedBuilder(
        animation: _confettiControllers[index],
        builder: (context, child) {
          // Seamless vertical bob: value(0) == value(1) == 0, no restart snap.
          final phase = _confettiPhase[index % _confettiPhase.length];
          final floatOffset = 6 *
              math.sin(
                2 *
                    math.pi *
                    ((_confettiControllers[index].value + phase) % 1.0),
              );
          return Positioned(
            left: piece.left * width,
            top: (piece.top * height) + floatOffset,
            child: Transform.rotate(
              angle: piece.rotation * math.pi / 180,
              child: piece.shape == _ConfettiShape.circle
                  ? Container(
                      width: piece.size,
                      height: piece.size,
                      decoration: BoxDecoration(
                        color: piece.color,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Container(
                      width: piece.size,
                      height: piece.size,
                      decoration: BoxDecoration(
                        color: piece.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        onTap: widget.onClose ?? () => Get.back(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
          ),
          child: const Icon(Icons.close, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      width: 162,
      height: 162,
      child: Stack(
        children: [
          // Food image with border and shadow
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.imageUrl != null
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
          ),
          // Green checkmark badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 4),
              ),
              child: const Icon(Icons.check, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFE8DDD0),
      child: const Icon(
        Icons.restaurant,
        size: 48,
        color: AppColors.textMedium,
      ),
    );
  }

  Widget _buildStatsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE3DB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            'steps_min_caps'.trParams({
              'steps': '${widget.totalSteps}',
              'min': '${widget.totalMinutes}',
            }),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'enjoy_your_meal'.tr,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: -0.6,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'you_just_cooked_full'.trParams({'recipe': widget.recipeName}),
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textMedium,
        height: 1.5,
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D6), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'rate_this_recipe'.tr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isFilled = index < _selectedRating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: isFilled
                        ? AppColors.starOrange
                        : const Color(0xFFE2D8C7),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: widget.onShare,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7DECE), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share_outlined, size: 18, color: AppColors.textDark),
            const SizedBox(width: 8),
            Text(
              'share_your_dish'.tr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ConfettiShape { square, circle }

class _ConfettiPiece {
  final Color color;
  final double size;
  final double rotation;
  final _ConfettiShape shape;
  final double left;
  final double top;
  final Duration duration;

  const _ConfettiPiece({
    required this.color,
    required this.size,
    required this.rotation,
    required this.shape,
    required this.left,
    required this.top,
    required this.duration,
  });
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
