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
    final localImage = box.read(imageKey) ?? '';

    // Show cached data instantly
    imagePath.value = localImage.isNotEmpty ? localImage : googleImage;

    final cachedName = box.read(nameKey) ?? '';
    name.value = cachedName.isNotEmpty ? cachedName : (user.displayName ?? '');

    // Load latest data from Firestore
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      final data = doc.data();

      if (data == null) return;

      // Prefer Firestore name
      final firestoreName = (data['name'] ?? '').toString().trim();

      if (firestoreName.isNotEmpty) {
        name.value = firestoreName;
        await box.write(nameKey, firestoreName);
      }

      // Prefer Firestore profile image
      final firestoreImage = (data['photoUrl'] ?? '').toString();

      if (firestoreImage.startsWith('http')) {
        imagePath.value = firestoreImage;
        await box.write(imageKey, firestoreImage);
      }
    } catch (_) {
      // Offline mode:
      // Keep cached name and image
    }
  }

  // Alias method
  // Can be called after profile update.
  Future<void> loadProfile() async {
    await loadUserData();
  }

  // ------------------------------------------------------------
  // PICK AND UPLOAD PROFILE IMAGE
  // ------------------------------------------------------------

  Future<void> pickImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return;

    // Instant local preview
    imagePath.value = file.path;
    await box.write(imageKey, file.path);

    final userId = uid;

    if (userId.isEmpty) return;

    try {
      final ref = FirebaseStorage.instance.ref(
        'users/$userId/profile/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await ref.putFile(File(file.path));

      final url = await ref.getDownloadURL();

      // Save image URL to Firestore
      await _firestore.collection('users').doc(userId).set({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Firebase Auth photo
      await _auth.currentUser?.updatePhotoURL(url);

      // Update observable and cache
      imagePath.value = url;
      await box.write(imageKey, url);
    } catch (_) {
      // Local preview remains if upload fails.
    }
  }

  // ------------------------------------------------------------
  // UPDATE NAME
  // ------------------------------------------------------------

  Future<void> updateName(String value) async {
    final newName = value.trim();

    if (newName.isEmpty) return;

    // Update UI instantly
    name.value = newName;

    // Update local cache
    await box.write(nameKey, newName);

    final userId = uid;

    if (userId.isEmpty) return;

    try {
      // Update Firebase Auth display name
      await _auth.currentUser?.updateDisplayName(newName);

      // Refresh Firebase Auth user
      await _auth.currentUser?.reload();

      // Update Firestore profile
      await _firestore.collection('users').doc(userId).set({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // UI and cache are already updated.
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

    // Update observable instantly
    name.value = cleanName;

    // Update local cache
    await box.write(nameKey, cleanName);

    // Update Firebase Auth
    await _auth.currentUser?.updateDisplayName(cleanName);
    await _auth.currentUser?.reload();

    // Update Firestore
    await _firestore.collection('users').doc(userId).set({
      'name': cleanName,
      if (contact != null) 'contact': contact.trim(),
      if (bio != null) 'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // PROFILE FILE
  // ------------------------------------------------------------

  File? get profileFile {
    final path = imagePath.value;

    if (path.isEmpty) return null;

    // Only return File for local file paths.
    // Firebase URLs should be used with NetworkImage.
    if (path.startsWith('http')) return null;

    return File(path);
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
