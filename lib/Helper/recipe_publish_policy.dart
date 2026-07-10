/// Single source of truth for the "who may publish a recipe to Discover" rule.
///
/// Every recipe carries ownership metadata:
///   • [sourceUserCreated] — the user wrote it themselves.
///   • [sourceImported]    — imported from web / photo / social / text.
///   • [sourceDiscovered]  — a private COPY saved from someone else's public
///     Discover recipe. These may be used privately but must NEVER be published
///     back to Discover (that would create a duplicate of the original).
///
/// This helper is pure Dart (no Flutter) so controllers, services, the editor
/// and the UI can all share the exact same rule, and the Firestore security
/// rules mirror it on the backend.
class RecipePublishPolicy {
  RecipePublishPolicy._();

  static const String sourceUserCreated = 'userCreated';
  static const String sourceImported = 'imported';
  static const String sourceDiscovered = 'discovered';

  /// Only user-created or imported recipes may ever become public.
  static bool canPublish(String? recipeSource) =>
      recipeSource != sourceDiscovered;

  /// A recipe that was saved out of Discover (and therefore can't be
  /// re-published).
  static bool isDiscovered(String? recipeSource) =>
      recipeSource == sourceDiscovered;

  /// Normalise a stored source value. Legacy saved copies predate
  /// [recipeSource] but set `savedFromRecipeId`, so infer 'discovered' for
  /// those; everything else without an explicit source is treated as
  /// user-created (so existing personal recipes stay publishable).
  static String resolveSource({
    String? recipeSource,
    Object? savedFromRecipeId,
  }) {
    if (recipeSource == sourceUserCreated ||
        recipeSource == sourceImported ||
        recipeSource == sourceDiscovered) {
      return recipeSource!;
    }
    return savedFromRecipeId != null ? sourceDiscovered : sourceUserCreated;
  }

  // ── User-facing copy (shared by every publish-blocked surface) ─────────────
  static const String cannotPublishTitle = 'Cannot Publish Recipe';
  static const String cannotPublishMessage =
      'This recipe was saved from Discover and cannot be published again. '
      'Only recipes you create yourself or import can be shared publicly.';

  /// Small inline hint shown beside a disabled Public toggle.
  static const String savedFromDiscoverHint =
      'Recipes saved from Discover cannot be published.';
}
