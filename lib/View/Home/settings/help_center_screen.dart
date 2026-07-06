import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/View/Home/settings/send_feedback_screen.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _query = '';
  int? _expanded;

  static const _topics = [
    ['Importing recipes', 'sparkF2', AppColors.primary, AppColors.redBg],
    ['Meal planning', 'cal', AppColors.blue, AppColors.blueBg],
    ['Groceries', 'cart', AppColors.green, AppColors.greenBgLight],
    ['Plus & billing', 'crown', AppColors.purple, AppColors.purpleBg],
  ];

  static const _faqs = [
    [
      "Why didn't my recipe import?",
      "Some sites block automated readers or don't publish structured recipe data. Try pasting the full recipe text manually, or use a different source link.",
    ],
    [
      'How do cook timers work?',
      'Timers appear automatically on steps that mention a duration. Tap one to start it — you\'ll get an alert when it finishes if timer notifications are on.',
    ],
    [
      'Can I cancel Plus anytime?',
      'Yes. Your Plus benefits stay active until the end of the current billing period, and you won\'t be charged again after cancelling.',
    ],
    [
      'How do I make a recipe public?',
      'Open one of your recipes, tap the ⋯ menu and choose the visibility option to switch it between Private and Public.',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final faqs = _faqs
        .asMap()
        .entries
        .where(
          (e) =>
              _query.isEmpty ||
              e.value[0].toString().toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            SettingsUi.header('Help center'),
            const SizedBox(height: 16),
            _searchBar(),
            const SizedBox(height: 18),

            SettingsUi.label(
              'BROWSE TOPICS',
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                for (final t in _topics)
                  _topicCard(
                    label: t[0] as String,
                    iconName: t[1] as String,
                    color: t[2] as Color,
                    bg: t[3] as Color,
                  ),
              ],
            ),

            const SizedBox(height: 22),
            SettingsUi.label(
              'POPULAR QUESTIONS',
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            ),
            SettingsUi.card(
              rows: [
                for (final e in faqs)
                  _faqRow(e.key, e.value[0].toString(), e.value[1].toString()),
              ],
            ),

            const SizedBox(height: 18),
            _contactButton(),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorderLight),
      ),
      child: Row(
        children: [
          const OnboardingLineIcon(
            'search',
            size: 20,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'Search help articles',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicCard({
    required String label,
    required String iconName,
    required Color color,
    required Color bg,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _query = ''),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: OnboardingLineIcon(iconName, size: 20, color: color),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqRow(int index, String question, String answer) {
    final open = _expanded == index;
    return InkWell(
      onTap: () => setState(() => _expanded = open ? null : index),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 22,
                  color: SettingsUi.chevron,
                ),
              ],
            ),
            if (open) ...[
              const SizedBox(height: 8),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contactButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => Get.to(() => const SendFeedbackScreen()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const OnboardingLineIcon('chat', size: 19, color: Colors.white),
        label: const Text(
          'Contact support',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
