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
    ['help_topic_importing', 'sparkF2', AppColors.primary, AppColors.redBg],
    ['help_topic_meal_planning', 'cal', AppColors.blue, AppColors.blueBg],
    ['groceries', 'cart', AppColors.green, AppColors.greenBgLight],
    ['help_topic_plus_billing', 'crown', AppColors.purple, AppColors.purpleBg],
  ];

  static const _faqs = [
    ['faq_q_import', 'faq_a_import'],
    ['faq_q_timers', 'faq_a_timers'],
    ['faq_q_cancel_plus', 'faq_a_cancel_plus'],
    ['faq_q_make_public', 'faq_a_make_public'],
  ];

  @override
  Widget build(BuildContext context) {
    final faqs = _faqs
        .asMap()
        .entries
        .where(
          (e) =>
              _query.isEmpty ||
              (e.value[0]).tr.toLowerCase().contains(
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
            SettingsUi.header('help_center'.tr),
            const SizedBox(height: 16),
            _searchBar(),
            const SizedBox(height: 18),

            SettingsUi.label(
              'browse_topics'.tr,
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
                    label: (t[0] as String).tr,
                    iconName: t[1] as String,
                    color: t[2] as Color,
                    bg: t[3] as Color,
                  ),
              ],
            ),

            const SizedBox(height: 22),
            SettingsUi.label(
              'popular_questions'.tr,
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            ),
            SettingsUi.card(
              rows: [
                for (final e in faqs)
                  _faqRow(e.key, (e.value[0]).tr, (e.value[1]).tr),
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
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                hintText: 'search_help_articles'.tr,
                hintStyle: const TextStyle(
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
        label: Text(
          'contact_support'.tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
