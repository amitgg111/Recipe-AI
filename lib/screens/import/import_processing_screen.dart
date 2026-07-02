import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';

class ImportProcessingScreen extends StatefulWidget {
  const ImportProcessingScreen({super.key});

  @override
  State<ImportProcessingScreen> createState() => _ImportProcessingScreenState();
}

class _ImportProcessingScreenState extends State<ImportProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _messageController;
  int _currentMessage = 0;

  final _messages = [
    'Gathering your favorite recipes…',
    'Setting up your cookbooks…',
    'Building your meal planner…',
    'Almost ready to cook…',
  ];

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _messageController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _messageController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _currentMessage = (_currentMessage + 1) % _messages.length);
        _messageController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text('Recipe AI', style: AppTextStyles.navLabel.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 46),
              _buildOrbitAnimation(),
              const SizedBox(height: 34),
              Text('Reading your recipe…', style: AppTextStyles.sectionTitle.copyWith(fontSize: 23)),
              const SizedBox(height: 8),
              Text(
                'Our AI is pulling out every detail so you don\'t have to.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              _buildProgressBar(),
              const SizedBox(height: 22),
              _buildChecklist(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrbitAnimation() {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.primary.withValues(alpha: 0.14), AppColors.primary.withValues(alpha: 0)],
              ),
            ),
          ),
          CustomPaint(size: const Size(188, 188), painter: _DashedCirclePainter()),
          AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _orbitController.value * 2 * math.pi,
                child: SizedBox(
                  width: 188,
                  height: 188,
                  child: Stack(
                    children: [
                      Positioned(left: 79, top: -4, child: _buildTomato()),
                      Positioned(right: -4, top: 82, child: _buildCheese()),
                      Positioned(left: 81, bottom: -4, child: _buildHerb()),
                      Positioned(left: -4, top: 75, child: _buildEgg()),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 0.75 + _pulseController.value * 1.15;
              final opacity = (1 - _pulseController.value).clamp(0.0, 0.55);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: opacity),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment(-0.5, -1),
                end: Alignment(0.5, 1),
                colors: [AppColors.primaryLight, AppColors.primary],
              ),
              boxShadow: const [BoxShadow(color: AppColors.primaryShadow, blurRadius: 30, offset: Offset(0, 16), spreadRadius: -10)],
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildTomato() => Container(
    width: 30, height: 30,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-0.36, -0.4), colors: [Color(0xFFFF6F52), Color(0xFFE5402A)]),
    ),
  );

  Widget _buildCheese() => Container(
    width: 32, height: 24,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const RadialGradient(center: Alignment(-0.36, -0.4), colors: [Color(0xFFFFE05A), Color(0xFFEBAE14)]),
    ),
  );

  Widget _buildHerb() => Container(
    width: 26, height: 26,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF54B069)),
  );

  Widget _buildEgg() => Container(
    width: 28, height: 30,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Colors.white, Color(0xFFEFE6D6)]),
    ),
  );

  Widget _buildProgressBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(color: const Color(0xFFEEE3D2), borderRadius: BorderRadius.circular(5)),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return FractionallySizedBox(
            widthFactor: 0.08 + (_progressController.value * 0.8),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChecklist() {
    return Column(
      children: [
        _checkItem('Found recipe title', true, 0),
        const SizedBox(height: 12),
        _checkItem('Extracting ingredients', true, 1),
        const SizedBox(height: 12),
        _checkItem('Reading the steps', false, 2),
      ],
    );
  }

  Widget _checkItem(String label, bool done, int index) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.greenBg : AppColors.redBg,
          ),
          child: Icon(
            done ? Icons.check : Icons.access_time,
            size: 16,
            color: done ? AppColors.green : AppColors.primary,
          ),
        ),
        const SizedBox(width: 11),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7DBC8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    const dashWidth = 4.0;
    const dashSpace = 8.0;
    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, dashWidth / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
