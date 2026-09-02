import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';

import 'package:recipe_ai/widgets/custom_snackbar.dart';
import 'package:recipe_ai/widgets/custom_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('ForgetPasswordScreen');
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: CustomText("forgot_password_title".tr)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              decoration: InputDecoration(hintText: "enter_email".tr),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  AnalyticsService.instance.trackButtonTap(
                    'send_reset_link',
                    screenName: 'ForgetPasswordScreen',
                  );
                  try {
                    await AuthService.forgotPassword(
                      emailController.text.trim(),
                    );
                    CustomSnackbar.show(
                      title: 'info'.tr,
                      message: 'reset_email_sent'.tr,
                      type: SnackbarType.info,
                    );
                  } catch (e) {
                    CustomSnackbar.show(
                      title: 'error'.tr,
                      message: AuthErrorMapper.message(e),
                      type: SnackbarType.error,
                    );
                  }
                },
                child: CustomText("send_reset_link".tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
