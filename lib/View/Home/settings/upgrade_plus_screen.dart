import 'package:flutter/material.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class UpgradePlusScreen extends StatefulWidget {
  const UpgradePlusScreen({super.key});

  @override
  State<UpgradePlusScreen> createState() => _UpgradePlusScreenState();
}

class _UpgradePlusScreenState extends State<UpgradePlusScreen> {
  int _plan = 1; // 0 monthly, 1 yearly

  static const _features = [
    ['Unlimited recipe imports', Icons.auto_awesome_rounded],
    ['Full nutrition breakdowns', Icons.local_fire_department_rounded],
    ['AI meal-plan auto-fill', Icons.calendar_month_rounded],
    ['Smart grocery categorising', Icons.shopping_cart_outlined],
    ['Ad-free, priority support', Icons.bolt_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: SettingsUi.header(
                'Plus',
                backIcon: Icons.close_rounded,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                children: [
                  _hero(),
                  const SizedBox(height: 22),
                  SettingsUi.card(
                    rows: [
                      for (final f in _features)
                        _featureRow(f[0] as String, f[1] as IconData),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _planCard(
                    index: 1,
                    title: 'Yearly',
                    price: '\$39.99 / year',
                    note: 'Best value · 2 months free',
                    highlighted: true,
                  ),
                  const SizedBox(height: 10),
                  _planCard(
                    index: 0,
                    title: 'Monthly',
                    price: '\$4.99 / month',
                    note: 'Billed monthly',
                    highlighted: false,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    CustomSnackbar.show(
                      title: 'Coming soon',
                      message: 'Plus subscriptions aren\'t available yet.',
                      type: SnackbarType.info,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _plan == 1
                        ? 'Start yearly — \$39.99'
                        : 'Start monthly — \$4.99',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D3BD4)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Recipe AI Plus',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cook smarter with unlimited imports, nutrition and AI planning.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 20, color: AppColors.purple),
        ],
      ),
    );
  }

  Widget _planCard({
    required int index,
    required String title,
    required String price,
    required String note,
    required bool highlighted,
  }) {
    final selected = _plan == index;
    return GestureDetector(
      onTap: () => setState(() => _plan = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.purple : AppColors.surfaceBorder,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.purple : AppColors.iconLight,
              size: 22,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (highlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purpleBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SAVE 33%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
