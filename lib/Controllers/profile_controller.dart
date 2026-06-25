import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final box = GetStorage();

  final RxString imagePath = ''.obs;
  final RxString name = ''.obs;

  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get imageKey => '${uid}_profile_image';
  String get nameKey => '${uid}_profile_name';

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final googleImage = user.photoURL ?? '';
    final localImage = box.read(imageKey) ?? '';

    // priority: local > google
    imagePath.value = localImage.isNotEmpty ? localImage : googleImage;

    name.value = box.read(nameKey) ?? (user.displayName ?? '');
  }

  Future<void> pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    imagePath.value = file.path;

    await box.write(imageKey, file.path);
  }

  Future<void> updateName(String value) async {
    name.value = value;

    await box.write(nameKey, value);
  }

  File? get profileFile {
    if (imagePath.value.isEmpty) return null;
    return File(imagePath.value);
  }

  void clearLocalData() {
    box.remove(imageKey);
    box.remove(nameKey);

    imagePath.value = '';
    name.value = '';
  }
}
