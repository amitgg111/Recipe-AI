import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';

import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/Widget/custom_text.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final emailController = TextEditingController();

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
              decoration: InputDecoration(hintText: "enter_email".tr),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
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
