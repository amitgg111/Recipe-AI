import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/notification_service.dart';
import 'package:recipe_ai/View/Home/settings/settings_common.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  final _push = NotificationService.instance;
  final _settings = Get.find<SettingsController>();

  // Whether the OS notification permission is granted. Null until resolved.
  bool _granted = false;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request permission the first time the screen is opened; afterwards just
    // reflect the current state (we never re-prompt — the OS wouldn't show the
    // dialog again, so a denied user gets the "Open settings" path instead).
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolvePermission());
    _push.addPermissionObserver(_onPermissionChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have flipped the permission in system settings and returned.
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _resolvePermission() async {
    if (!_push.isConfigured) return;
    // Fallback ask: only prompts if it wasn't granted during onboarding and we
    // haven't already prompted from settings.
    if (!_push.hasPermission) {
      await _push.requestPermissionFromSettings();
    }
    await _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    if (!_push.isConfigured) return;
    final granted = _push.hasPermission;
    final asked = _push.askedInSettings;
    if ((granted != _granted || asked != _asked) && mounted) {
      setState(() {
        _granted = granted;
        _asked = asked;
      });
    }
    // Re-sync scheduled reminders with the (possibly changed) permission.
    await _settings.reconcileNotifications();
  }

  void _onPermissionChanged(bool granted) {
    if (mounted) setState(() => _granted = granted);
    _settings.reconcileNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final showBanner = _push.isConfigured && _asked && !_granted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            SettingsUi.header('notifications'.tr),
            const SizedBox(height: 4),

            if (showBanner) ...[
              const SizedBox(height: 8),
              _PermissionBanner(onOpenSettings: _push.openSystemSettings),
            ],

            SettingsUi.label('section_cooking'.tr,
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 9)),
            SettingsUi.card(
              rows: [
                _toggle(
                  'cook_timer_alerts'.tr,
                  'cook_timer_alerts_sub'.tr,
                  s.cookTimerAlerts,
                  s.setCookTimerAlerts,
                ),
                _toggle(
                  'meal_plan_reminders'.tr,
                  'daily_at_9am'.tr,
                  s.mealPlanReminders,
                  s.setMealPlanReminders,
                ),
              ],
            ),

            SettingsUi.label('section_shopping_community'.tr),
            SettingsUi.card(
              rows: [
                _toggle(
                  'weekly_grocery_reminder'.tr,
                  'sundays_before_shopping'.tr,
                  s.weeklyGroceryReminder,
                  s.setWeeklyGroceryReminder,
                ),
                _toggle(
                  'likes_and_comments'.tr,
                  'activity_on_your_recipes'.tr,
                  s.likesAndComments,
                  s.setLikesAndComments,
                ),
                _toggle(
                  'new_followers'.tr,
                  'when_someone_follows_you'.tr,
                  s.newFollowers,
                  s.setNewFollowers,
                ),
              ],
            ),

            SettingsUi.label('section_general'.tr),
            SettingsUi.card(
              rows: [
                _toggle(
                  'product_news_tips'.tr,
                  'occasional_updates'.tr,
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

/// Shown only when the OS notification permission has been denied — offers a
/// single "Open settings" action instead of re-prompting.
class _PermissionBanner extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionBanner({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded,
              size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notifications_are_off'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'enable_notifications_hint'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onOpenSettings,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'open'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
