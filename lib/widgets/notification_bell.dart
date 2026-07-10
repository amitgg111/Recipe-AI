import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_ai/Controllers/notification_controller.dart';
import 'package:recipe_ai/View/Home/notifications_screen.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

/// Bell icon with a live unread badge (🔔 5). The count is driven by
/// [NotificationController.unreadCount], a real-time Firestore listener, so it
/// updates everywhere the bell is shown.
class NotificationBell extends StatelessWidget {
  final Color color;
  final double size;
  const NotificationBell({
    super.key,
    this.color = const Color(0xFF2A211B),
    this.size = 23,
  });

  @override
  Widget build(BuildContext context) {
    // Fall back gracefully if the controller isn't registered yet.
    if (!Get.isRegistered<NotificationController>()) {
      return _bell(0);
    }
    final c = Get.find<NotificationController>();
    return Obx(() => _bell(c.unreadCount.value));
  }

  Widget _bell(int count) {
    return GestureDetector(
      onTap: () => Get.to(() => const NotificationsScreen()),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            OnboardingLineIcon('bell', size: size, color: color),
            if (count > 0)
              Positioned(
                right: -6,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  height: 17,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2623E),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
