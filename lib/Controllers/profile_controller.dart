import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final googleImage = user.photoURL ?? '';
    final localImage = box.read(imageKey) ?? '';

    // Paint instantly from the cached value (local file OR previously-synced URL).
    imagePath.value = localImage.isNotEmpty ? localImage : googleImage;
    name.value = box.read(nameKey) ?? (user.displayName ?? '');

    // Then prefer the Firestore-hosted avatar so it follows the account across
    // devices (the picked photo is now uploaded — no longer device-only).
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final url = (doc.data()?['photoUrl'] ?? '').toString();
      if (url.startsWith('http')) {
        imagePath.value = url;
        await box.write(imageKey, url);
      }
    } catch (_) {/* offline — keep the cached value */}
  }

  Future<void> pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    // Instant local preview while it uploads.
    imagePath.value = file.path;
    await box.write(imageKey, file.path);

    // Upload to Firebase Storage and store the URL on the profile doc so the
    // avatar is no longer device-only.
    final u = uid;
    if (u.isEmpty) return;
    try {
      final ref = FirebaseStorage.instance
          .ref('users/$u/profile/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('users').doc(u).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(url);
      imagePath.value = url;
      await box.write(imageKey, url);
    } catch (_) {
      // Upload failed — the local preview stays; it'll retry next pick.
    }
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
