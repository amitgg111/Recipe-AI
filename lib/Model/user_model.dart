import 'package:cloud_firestore/cloud_firestore.dart';

/// A public user profile, backed by the `users/{uid}` document.
class UserModel {
  final String uid;
  final String bio;
  final String photoUrl;
  final String email;
  final int followersCount;
  final int followingCount;

  const UserModel({
    required this.uid,
    required this.bio,
    required this.photoUrl,
    required this.email,
    required this.followersCount,
    required this.followingCount,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      bio: (data['bio'] as String?)?.trim() ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Display name — derived from email (never stored as a separate
  /// username field), with a generic fallback.
  String get displayName {
    if (email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return 'Recipe creator';
  }

  /// First letter for avatar placeholder.
  String get initial => displayName.substring(0, 1).toUpperCase();
}
