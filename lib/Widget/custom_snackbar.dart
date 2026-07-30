import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/theme/app_colors.dart';

enum SnackbarType { success, error, warning, info }

class CustomSnackbar {
  static Future<void> show({
    required String title,
    String? message,
    String? actionText,
    VoidCallback? onAction,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 2),
  }) async {
    Get.closeAllSnackbars();

    final config = await _getConfig(type);

    Get.rawSnackbar(
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 18,
      backgroundColor: Colors.transparent,
      duration: duration,
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: config.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: Colors.white, size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),

                  if (message != null && message.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (actionText != null)
              TextButton(
                onPressed: () {
                  Get.closeCurrentSnackbar();
                  onAction?.call();
                },
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Future<_SnackbarConfig> _getConfig(SnackbarType type) async {
    switch (type) {
      case SnackbarType.success:
        return const _SnackbarConfig(
          color: Colors.green,
          icon: Icons.check_circle,
        );

      case SnackbarType.error:
        return const _SnackbarConfig(color: Colors.red, icon: Icons.error);

      case SnackbarType.warning:
        return const _SnackbarConfig(
          color: Colors.orange,
          icon: Icons.warning_amber,
        );

      case SnackbarType.info:
        return await _getInfoConfig();
    }
  }

  static Future<_SnackbarConfig> _getInfoConfig() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // User login nathi hoy
      if (user == null) {
        return const _SnackbarConfig(
          color: AppColors.primary,
          icon: Icons.info,
        );
      }

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDocument.data();

      final bool isPlusUser = data?['isPlus'] == true;

      if (isPlusUser) {
        return const _SnackbarConfig(color: AppColors.purple, icon: Icons.info);
      }

      return const _SnackbarConfig(color: AppColors.primary, icon: Icons.info);
    } catch (e) {
      // Firebase error hoy to normal user color
      return const _SnackbarConfig(color: Colors.orange, icon: Icons.info);
    }
  }
}

class _SnackbarConfig {
  final Color color;
  final IconData icon;

  const _SnackbarConfig({required this.color, required this.icon});
}
