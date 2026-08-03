import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final GetStorage box = GetStorage();

  final RxString imagePath = ''.obs;
  final RxString name = ''.obs;
  final RxBool isUploadingImage = false.obs;
  final RxBool isLocalPreview = false.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  String get imageKey => '${uid}_profile_image';
  String get nameKey => '${uid}_profile_name';

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  // ------------------------------------------------------------
  // LOAD USER DATA
  // ------------------------------------------------------------

  Future<void> loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final googleImage = user.photoURL ?? '';
    final cachedImage = box.read(imageKey)?.toString() ?? '';

    // Cached image instantly show.
    if (cachedImage.isNotEmpty) {
      imagePath.value = cachedImage;
    } else if (googleImage.isNotEmpty) {
      imagePath.value = googleImage;
    }

    final cachedName = box.read(nameKey)?.toString() ?? '';

    if (cachedName.isNotEmpty) {
      name.value = cachedName;
    } else {
      name.value = user.displayName ?? '';
    }

    // Latest Firestore data background ma fetch.
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      final data = doc.data();

      if (data == null) return;

      final firestoreName = (data['name'] ?? '').toString().trim();

      if (firestoreName.isNotEmpty) {
        name.value = firestoreName;
        await box.write(nameKey, firestoreName);
      }

      final firestoreImage = (data['photoUrl'] ?? '').toString().trim();

      if (firestoreImage.startsWith('http') &&
          !isLocalPreview.value &&
          !isUploadingImage.value) {
        imagePath.value = firestoreImage;
        await box.write(imageKey, firestoreImage);
      }
    } catch (_) {
      // Cached data remains available offline.
    }
  }

  Future<void> loadProfile() async {
    await loadUserData();
  }

  // ------------------------------------------------------------
  // PICK PROFILE IMAGE
  // ------------------------------------------------------------

  Future<void> pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final userId = uid;

    if (userId.isEmpty) return;

    // ----------------------------------------------------------
    // INSTANT PREVIEW
    // ----------------------------------------------------------

    isLocalPreview.value = true;
    imagePath.value = file.path;

    // Local path cache ma immediately save.
    await box.write(imageKey, file.path);

    // Loader/upload state.
    isUploadingImage.value = true;

    // ----------------------------------------------------------
    // BACKGROUND UPLOAD
    // ----------------------------------------------------------

    unawaited(_uploadProfileImage(userId: userId, file: file));
  }

  // ------------------------------------------------------------
  // UPLOAD PROFILE IMAGE
  // ------------------------------------------------------------

  Future<void> _uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(
        'users/$userId/profile/$fileName',
      );

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=31536000',
        ),
      );

      final url = await ref.getDownloadURL();

      // Firestore background update.
      await _firestore.collection('users').doc(userId).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Auth background update.
      await _auth.currentUser?.updatePhotoURL(url);

      // Save final URL.
      await box.write(imageKey, url);

      // IMPORTANT:
      // Local preview already visible છે.
      // Have network URL ma switch karvani jarur nathi.
      //
      // Local preview screen par j rehse.
      // Next time app/profile load thase tyare URL use thase.
    } catch (e) {
      // Local preview visible રહેવા દો.
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ------------------------------------------------------------
  // UPDATE NAME
  // ------------------------------------------------------------

  Future<void> updateName(String value) async {
    final newName = value.trim();

    if (newName.isEmpty) return;

    // Instant UI update.
    name.value = newName;

    await box.write(nameKey, newName);

    final userId = uid;

    if (userId.isEmpty) return;

    try {
      await _auth.currentUser?.updateDisplayName(newName);

      await _auth.currentUser?.reload();

      await _firestore.collection('users').doc(userId).set({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // UI/cache already updated.
    }
  }

  // ------------------------------------------------------------
  // UPDATE COMPLETE PROFILE
  // ------------------------------------------------------------

  Future<void> updateProfile({
    required String newName,
    String? contact,
    String? bio,
  }) async {
    final userId = uid;

    if (userId.isEmpty) return;

    final cleanName = newName.trim();

    // Instant UI update.
    name.value = cleanName;

    await box.write(nameKey, cleanName);

    try {
      await _auth.currentUser?.updateDisplayName(cleanName);

      await _auth.currentUser?.reload();

      await _firestore.collection('users').doc(userId).set({
        'name': cleanName,
        if (contact != null) 'contact': contact.trim(),
        if (bio != null) 'bio': bio.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // UI/cache already updated.
    }
  }

  // ------------------------------------------------------------
  // PROFILE FILE
  // ------------------------------------------------------------

  File? get profileFile {
    final path = imagePath.value;

    if (path.isEmpty || path.startsWith('http')) {
      return null;
    }

    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    return file;
  }

  // ------------------------------------------------------------
  // CLEAR LOCAL DATA
  // ------------------------------------------------------------

  void clearLocalData() {
    box.remove(imageKey);
    box.remove(nameKey);

    imagePath.value = '';
    name.value = '';
  }
}
