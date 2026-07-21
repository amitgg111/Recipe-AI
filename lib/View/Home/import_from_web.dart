import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/View/Home/import_complete_screen.dart';
import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/widgets/onboarding_line_icon.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:recipe_ai/Controllers/import_web_controller.dart';

class ImportFromWebScreen extends StatefulWidget {
  const ImportFromWebScreen({super.key});

  @override
  State<ImportFromWebScreen> createState() => _ImportFromWebScreenState();
}

class _ImportFromWebScreenState extends State<ImportFromWebScreen> {
  // Defensive: normally registered permanently in main(), but if it was ever
  // removed, re-create it here so entering this screen can never throw
  // "ImportWebController not found".
  final ImportWebController controller = Get.isRegistered<ImportWebController>()
      ? Get.find<ImportWebController>()
      : Get.put(ImportWebController(), permanent: true);

  // True for the whole import (scrape → image → save). Keeps the full-screen
  // loader up, disables the Import button, and blocks back — set/reset only in
  // [_runWebImport]'s try/finally so the loading state can never get stuck.
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    // The controller is permanent, so the webview keeps its last page across
    // visits. Reset to the clean landing page on every entry so returning to
    // this screen always shows a fresh, empty page — never the old search
    // results or the previously-opened website.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLandingPage();
    });
  }

  /// Full web import: show the animated processing screen, scrape the current
  /// page, save it (which also generates the dish image), then hand off to the
  /// shared review screen — exactly like every other import path. The
  /// [_importing] flag keeps the loader up and blocks back, and is always
  /// cleared in the finally so it can never get stuck.
  Future<void> _runWebImport(ImportWebController controller) async {
    if (_importing) return; // prevent parallel / double imports
    // The [_importing] flag drives the full-screen loader OVERLAY in build()
    // (no route is pushed, so there's no PopScope that blocks dismissal on
    // failure). The overlay is up before any async work → no late flicker.
    setState(() => _importing = true);

    var navigated = false;
    try {
      final data = await controller.scrapeCurrentPage();
      if (data == null) {
        throw Exception('Could not read a recipe from this page.');
      }

      final model = await controller.saveRecipe(data);
      if (model == null) {
        throw Exception('Could not save this recipe.');
      }

      if (!mounted) return;
      // Navigate WHILE the loader is still up so the browser never flashes
      // between the loader disappearing and the review screen appearing.
      navigated = true;
      Get.off(
        () => ImportCompleteScreen(recipe: model),
        transition: Transition.fadeIn,
      );
    } catch (e) {
      CustomSnackbar.show(
        title: 'import_failed'.tr,
        message: 'import_failed_message'.tr,
        type: SnackbarType.error,
      );
    } finally {
      // Always clear the loading state (unless we've navigated away and the
      // widget is being disposed) so it can never get stuck.
      if (mounted && !navigated) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_importing) return; // no navigation while importing

        final canGoBack = await controller.webViewController.canGoBack();

        if (canGoBack) {
          controller.webViewController.goBack();
        } else {
          controller.loadLandingPage();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface(context),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: controller.webViewController),
                    Obx(
                      () => controller.isLoading.value
                          ? const _PageLoadingOverlay()
                          : const SizedBox.shrink(),
                    ),

                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: () {
                          // Reset to the clean landing page and leave. The
                          // controller is registered permanently in main(), so
                          // it must NOT be deleted here — deleting it makes the
                          // next Get.find<ImportWebController>() throw
                          // "ImportWebController not found" on re-entry.
                          controller.loadLandingPage();
                          Get.back();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: const Color(0xFFEFEDE6)),
                          ),
                          child: const OnboardingLineIcon(
                            'back',
                            size: 19,
                            color: Color(0xFF2A211B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // The bottom bar (import button + browser nav) appears only once
              // the user has opened an actual website — it stays hidden on the
              // landing screen and the search-results page.
              Obx(
                () => controller.showImportBar
                    ? _buildImportBar(controller, context)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportBar(ImportWebController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surface(context).withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        // Loading for the WHOLE import (scrape → image → save), shown only on
        // the button — no full-screen overlay.
        final loading = _importing || controller.isImporting.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Handle
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary(context),
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            const SizedBox(height: 18),

            if (controller.showImportBar)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : () => _runWebImport(controller),
                  icon: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: CustomText(
                    loading ? "importing".tr : "import_recipe".tr,

                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  OnboardingLineIcon(
                    'book',
                    size: 34,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    "open_a_recipe_to_import".tr,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    "browse_recipe_website".tr,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        );
      }),
    );
  }
}

class _PageLoadingOverlay extends StatelessWidget {
  const _PageLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8DDD2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              CustomText('loading_recipe_page'.tr, fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ),
    );
  }
}
