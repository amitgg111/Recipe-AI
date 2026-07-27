// import 'dart:developer';
// import 'dart:io';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
// import 'package:recipe_ai/theme/app_colors.dart';

// class RecipeCameraScreen extends StatefulWidget {
//   const RecipeCameraScreen({super.key});

//   @override
//   State<RecipeCameraScreen> createState() => _RecipeCameraScreenState();
// }

// class _RecipeCameraScreenState extends State<RecipeCameraScreen> {
//   CameraController? _cameraController;
//   List<CameraDescription> _cameras = [];

//   bool _isInitializing = true;
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }

//   Future<void> _initializeCamera() async {
//     try {
//       final permissionStatus = await Permission.camera.status;

//       if (permissionStatus.isGranted) {
//         await _setupCamera();
//         return;
//       }

//       final result = await Permission.camera.request();

//       if (result.isGranted) {
//         await _setupCamera();
//       } else {
//         if (result.isPermanentlyDenied) {
//           await openAppSettings();
//         }

//         if (mounted) {
//           setState(() {
//             _isInitializing = false;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('Camera initialization error: $e');

//       if (mounted) {
//         setState(() {
//           _isInitializing = false;
//         });
//       }
//     }
//   }

//   Future<void> _setupCamera() async {
//     _cameras = await availableCameras();

//     if (_cameras.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _isInitializing = false;
//         });
//       }
//       return;
//     }

//     final camera = _cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.back,
//       orElse: () => _cameras.first,
//     );

//     _cameraController = CameraController(
//       camera,
//       ResolutionPreset.high,
//       enableAudio: false,
//     );

//     await _cameraController!.initialize();

//     if (mounted) {
//       setState(() {
//         _isInitializing = false;
//       });
//     }
//   }

//   Future<void> _captureRecipe() async {
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized ||
//         _isProcessing) {
//       return;
//     }

//     try {
//       final image = await _cameraController!.takePicture();
//       await _showImageConfirmation(File(image.path));

//       log('-----------done');
//     } catch (e) {
//       log('Capture error: $e');

//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }

//   Future<void> _pickFromGallery() async {
//     if (_isProcessing) return;

//     final picker = ImagePicker();

//     final pickedImage = await picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 90,
//     );

//     if (pickedImage == null) return;

//     await _showImageConfirmation(File(pickedImage.path));

//   }

//   Future<void> _processRecipeImage(File image) async {
//     try {
//       await RecipeImportService.importRecipeFromImage(context, image);

//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Recipe image processing error: $e');

//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = _cameraController;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             if (_isInitializing)
//               const Center(
//                 child: CircularProgressIndicator(color: Colors.white),
//               )
//             else if (controller != null && controller.value.isInitialized)
//               CameraPreview(controller)
//             else
//               const Center(
//                 child: Text(
//                   'Unable to access camera',
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                 ),
//               ),

//             // Dark overlay around scanning area.
//             IgnorePointer(
//               child: CustomPaint(painter: _ScannerOverlayPainter()),
//             ),

//             // Top bar.
//             Positioned(
//               top: 16,
//               left: 16,
//               right: 16,
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Get.back(),
//                     child: Container(
//                       width: 44,
//                       height: 44,
//                       decoration: BoxDecoration(
//                         color: Colors.black.withValues(alpha: 0.45),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.close_rounded,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                     ),
//                   ),

//                   const Spacer(),

//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withValues(alpha: 0.45),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Row(
//                       children: [
//                         Icon(
//                           Icons.auto_awesome_rounded,
//                           color: Colors.white,
//                           size: 15,
//                         ),
//                         SizedBox(width: 6),
//                         Text(
//                           'Scan Recipe',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Instruction.
//             Positioned(
//               top: 92,
//               left: 24,
//               right: 24,
//               child: Column(
//                 children: [
//                   const Text(
//                     'Scan your recipe',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Place the recipe clearly inside the frame',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withValues(alpha: 0.8),
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Scanning frame.
//             Positioned(
//               left: 32,
//               right: 32,
//               top: MediaQuery.of(context).size.height * 0.25,
//               height: MediaQuery.of(context).size.height * 0.36,
//               child: Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(
//                     color: Colors.white.withValues(alpha: 0.85),
//                     width: 2,
//                   ),
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//               ),
//             ),

//             // Bottom controls.
//             Positioned(
//               left: 0,
//               right: 0,
//               bottom: 28,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Gallery button - bottom left.
//                   SizedBox(
//                     width: 82,
//                     child: GestureDetector(
//                       onTap: _pickFromGallery,
//                       child: Column(
//                         children: [
//                           Container(
//                             width: 52,
//                             height: 52,
//                             decoration: BoxDecoration(
//                               color: Colors.white.withValues(alpha: 0.18),
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                 color: Colors.white.withValues(alpha: 0.4),
//                               ),
//                             ),
//                             child: const Icon(
//                               Icons.photo_library_outlined,
//                               color: Colors.white,
//                               size: 25,
//                             ),
//                           ),
//                           const SizedBox(height: 7),
//                           const Text(
//                             'Gallery',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 32),

//                   // Camera capture button.
//                   GestureDetector(
//                     onTap: _captureRecipe,
//                     child: Container(
//                       width: 76,
//                       height: 76,
//                       padding: const EdgeInsets.all(5),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 3),
//                       ),
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(width: 114),
//                 ],
//               ),
//             ),

//             // Processing overlay.
//             if (_isProcessing)
//               Container(
//                 color: Colors.black.withValues(alpha: 0.65),
//                 child: const Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CircularProgressIndicator(color: Colors.white),
//                       SizedBox(height: 16),
//                       Text(
//                         'Detecting your recipe...',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _showImageConfirmation(File image) async {
//     final shouldProcess = await Get.dialog<bool>(
//       Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.all(20),
//         child: Container(
//           decoration: BoxDecoration(
//             color: AppColors.background,
//             borderRadius: BorderRadius.circular(24),
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(18),
//                 child: Image.file(
//                   image,
//                   height: 360,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),

//               const SizedBox(height: 18),

//               const Text(
//                 'Use this photo?',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
//               ),

//               const SizedBox(height: 6),

//               Text(
//                 'Make sure the recipe is clearly visible.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//               ),

//               const SizedBox(height: 20),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Get.back(result: false),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: const Text('Retake'),
//                     ),
//                   ),

//                   const SizedBox(width: 12),

//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => Get.back(result: true),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: const Text('Use Photo'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//     if (shouldProcess == true && mounted) {
//       setState(() {
//         _isProcessing = true;
//       });

//       await _processRecipeImage(image);
//     } else if (mounted) {
//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

// }

// class _ScannerOverlayPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.black.withValues(alpha: 0.38)
//       ..style = PaintingStyle.fill;

//     final scanRect = RRect.fromRectAndRadius(
//       Rect.fromLTWH(
//         32,
//         size.height * 0.27,
//         size.width - 64,
//         size.height * 0.38,
//       ),
//       const Radius.circular(24),
//     );

//     final path = Path()
//       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
//       ..addRRect(scanRect)
//       ..fillType = PathFillType.evenOdd;

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:recipe_ai/Service/import_with_image_api_calling_service.dart';
import 'package:recipe_ai/theme/app_colors.dart';

class RecipeCameraScreen extends StatefulWidget {
  const RecipeCameraScreen({super.key});

  @override
  State<RecipeCameraScreen> createState() => _RecipeCameraScreenState();
}

class _RecipeCameraScreenState extends State<RecipeCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isInitializing = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final permissionStatus = await Permission.camera.status;

      if (permissionStatus.isGranted) {
        await _setupCamera();
        return;
      }

      final result = await Permission.camera.request();

      if (result.isGranted) {
        await _setupCamera();
      } else {
        if (result.isPermanentlyDenied) {
          await openAppSettings();
        }

        if (mounted) {
          setState(() => _isInitializing = false);
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      return;
    }

    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _captureRecipe() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();

      await _showImageConfirmation(File(image.path));

      log('-----------done');
    } catch (e) {
      log('Capture error: $e');

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedImage == null) return;

    await _showImageConfirmation(File(pickedImage.path));
  }

  Future<void> _processRecipeImage(File image) async {
    try {
      await RecipeImportService.importRecipeFromImage(context, image);
    } catch (e) {
      debugPrint('Recipe image processing error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Responsive horizontal padding.
            final horizontalPadding = screenWidth < 360 ? 20.0 : 28.0;

            // Responsive scanner dimensions.

            final scannerHeight = (screenHeight * 0.38).clamp(240.0, 390.0);

            final scannerTop = (screenHeight * 0.26).clamp(190.0, 260.0);

            return Stack(
              fit: StackFit.expand,
              children: [
                // ─────────────────────────────────────────────
                // CAMERA
                // ─────────────────────────────────────────────
                if (_isInitializing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (controller != null && controller.value.isInitialized)
                  _buildCameraPreview(controller)
                else
                  const Center(
                    child: Text(
                      'Unable to access camera',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                // ─────────────────────────────────────────────
                // DARK OVERLAY
                // ─────────────────────────────────────────────
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ScannerOverlayPainter(
                      horizontalPadding: horizontalPadding,
                      scannerTop: scannerTop,
                      scannerHeight: scannerHeight,
                      borderRadius: 24,
                    ),
                  ),
                ),

                // ─────────────────────────────────────────────
                // TOP BAR
                // ─────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: _buildTopBar(),
                ),

                // ─────────────────────────────────────────────
                // HEADER
                // ─────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 88,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  child: _buildHeader(),
                ),

                // ─────────────────────────────────────────────
                // SCANNER FRAME
                // ─────────────────────────────────────────────
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: scannerTop,
                  height: scannerHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

                // ─────────────────────────────────────────────
                // BOTTOM CONTROLS
                // ─────────────────────────────────────────────
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  child: _buildBottomControls(screenWidth: screenWidth),
                ),

                // ─────────────────────────────────────────────
                // PROCESSING OVERLAY
                // ─────────────────────────────────────────────
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Detecting your recipe...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildCircleButton(icon: Icons.close_rounded, onTap: () => Get.back()),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text(
                'Scan Recipe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Scan your recipe',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Place the recipe clearly inside the frame',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls({required double screenWidth}) {
    final captureSize = screenWidth < 360 ? 68.0 : 76.0;
    final gallerySize = screenWidth < 360 ? 48.0 : 52.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gallery
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _pickFromGallery,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: gallerySize,
                    height: gallerySize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Capture
        GestureDetector(
          onTap: _captureRecipe,
          child: Container(
            width: captureSize,
            height: captureSize,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Empty space equal to gallery area.
        Expanded(child: const SizedBox()),
      ],
    );
  }

  Future<void> _showImageConfirmation(File image) async {
    final screenHeight = MediaQuery.of(context).size.height;

    final shouldProcess = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Use this photo?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Make sure the recipe is clearly visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(result: false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Retake'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(result: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Use Photo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (shouldProcess == true && mounted) {
      setState(() => _isProcessing = true);
      await _processRecipeImage(image);
    } else if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double horizontalPadding;
  final double scannerTop;
  final double scannerHeight;
  final double borderRadius;

  const _ScannerOverlayPainter({
    required this.horizontalPadding,
    required this.scannerTop,
    required this.scannerHeight,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    final scanRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontalPadding,
        scannerTop,
        size.width - (horizontalPadding * 2),
        scannerHeight,
      ),
      Radius.circular(borderRadius),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(scanRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.scannerTop != scannerTop ||
        oldDelegate.scannerHeight != scannerHeight;
  }
}
