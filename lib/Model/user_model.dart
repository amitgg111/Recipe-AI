// import 'package:cloud_firestore/cloud_firestore.dart';

// /// A public user profile, backed by the `users/{uid}` document.
// class UserModel {
//   final String uid;
//   final String name;

//   final String bio;
//   final String photoUrl;
//   final String email;
//   final int followersCount;
//   final int followingCount;

//   const UserModel({
//     required this.uid,
//     required this.name,

//     required this.bio,
//     required this.photoUrl,
//     required this.email,
//     required this.followersCount,
//     required this.followingCount,
//   });

//   factory UserModel.fromDoc(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>? ?? {};
//     return UserModel(
//       uid: doc.id,
//       name: (data['name'] as String?)?.trim() ?? '',

//       bio: (data['bio'] as String?)?.trim() ?? '',
//       photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
//       email: (data['email'] as String?)?.trim() ?? '',
//       followersCount: (data['followersCount'] as num?)?.toInt() ?? 0,
//       followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
//     );
//   }

//   /// Display name with a sensible fallback.
//   String get displayName => name.isNotEmpty ? name : 'Recipe creator';

//   /// A `@handle` — the stored username, else derived from email/name/uid.
//   String get handle {
//     if (name.isNotEmpty) return name;
//     final base = email.contains('@')
//         ? email.split('@').first
//         : (name.isNotEmpty ? name : 'chef');
//     final clean = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
//     final suffix = uid.length >= 4 ? uid.substring(0, 4) : uid;
//     return '${clean.isEmpty ? 'chef' : clean}$suffix';
//   }

//   /// First letter for avatar placeholder.
//   String get initial =>
//       (name.isNotEmpty ? name : handle).substring(0, 1).toUpperCase();
// }

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
