import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app social notification (like / comment / follow) written by the
/// backend Cloud Functions into the top-level `notifications` collection.
class AppNotification {
  final String id;
  final String receiverUserId;
  final String senderUserId;

  /// 'like' | 'comment' | 'follow'.
  final String type;

  final String? recipeId;
  final String? commentId;
  final String title;
  final String message;
  final String senderName;
  final String senderPhoto;
  final String? recipeImage;
  final String? recipeTitle;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.receiverUserId,
    required this.senderUserId,
    required this.type,
    required this.recipeId,
    required this.commentId,
    required this.title,
    required this.message,
    required this.senderName,
    required this.senderPhoto,
    required this.recipeImage,
    required this.recipeTitle,
    required this.isRead,
    required this.createdAt,
  });

  bool get isLike => type == 'like';
  bool get isComment => type == 'comment';
  bool get isFollow => type == 'follow';
  bool get isSave => type == 'save';

  /// True for types that point at a recipe (and so show a recipe thumbnail).
  bool get hasRecipe =>
      (recipeId != null && recipeId!.isNotEmpty) &&
      (isLike || isComment || isSave);

  factory AppNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    return AppNotification(
      id: doc.id,
      receiverUserId: d['receiverUserId']?.toString() ?? '',
      senderUserId: d['senderUserId']?.toString() ?? '',
      type: d['type']?.toString() ?? '',
      recipeId: (d['recipeId'] as String?),
      commentId: (d['commentId'] as String?),
      title: d['title']?.toString() ?? '',
      message: d['message']?.toString() ?? '',
      senderName: d['senderName']?.toString() ?? 'Someone',
      senderPhoto: d['senderPhoto']?.toString() ?? '',
      recipeImage: (d['recipeImage'] as String?),
      recipeTitle: (d['recipeTitle'] as String?),
      isRead: d['isRead'] == true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
