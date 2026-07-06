import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const CustomText("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Enter Email"),
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
                      title: 'Info',
                      message: 'Reset email sent',
                      type: SnackbarType.info,
                    );
                  } catch (e) {
                    CustomSnackbar.show(
                      title: 'Error',
                      message: AuthErrorMapper.message(e),
                      type: SnackbarType.error,
                    );
                  }
                },
                child: const CustomText("Send Reset Link"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
