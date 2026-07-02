import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            SettingsUi.header('Notifications'),
            const SizedBox(height: 4),

            SettingsUi.label('COOKING', padding: const EdgeInsets.fromLTRB(4, 4, 4, 9)),
            SettingsUi.card(
              rows: [
                _toggle(
                  'Cook timer alerts',
                  'When a step timer finishes',
                  s.cookTimerAlerts,
                  s.setCookTimerAlerts,
                ),
                _toggle(
                  'Meal plan reminders',
                  'Daily at 9:00 AM',
                  s.mealPlanReminders,
                  s.setMealPlanReminders,
                ),
              ],
            ),

            SettingsUi.label('SHOPPING & COMMUNITY'),
            SettingsUi.card(
              rows: [
                _toggle(
                  'Weekly grocery reminder',
                  'Sundays before shopping',
                  s.weeklyGroceryReminder,
                  s.setWeeklyGroceryReminder,
                ),
                _toggle(
                  'Likes & comments',
                  'Activity on your recipes',
                  s.likesAndComments,
                  s.setLikesAndComments,
                ),
                _toggle(
                  'New followers',
                  'When someone follows you',
                  s.newFollowers,
                  s.setNewFollowers,
                ),
              ],
            ),

            SettingsUi.label('GENERAL'),
            SettingsUi.card(
              rows: [
                _toggle(
                  'Product news & tips',
                  'Occasional updates',
                  s.productNews,
                  s.setProductNews,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    RxBool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Obx(() => SettingsSwitch(value: value.value, onChanged: onChanged)),
        ],
      ),
    );
  }
}
