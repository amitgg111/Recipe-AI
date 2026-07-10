import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The single remote-image widget used across the app.
///
/// Wraps [CachedNetworkImage] so every network image is:
///  * cached to DISK and memory — a second view is instant and scrolling a
///    list back and forth never re-downloads. (Bare `Image.network` keeps no
///    disk cache, so it re-fetched on every rebuild — the reason images felt
///    slow to load.)
///  * decoded at a capped pixel width ([memCacheWidth] / [maxWidthDiskCache])
///    so a large source image doesn't stall decoding into a small slot,
///  * shown with a light placeholder while loading and a fallback on error.
///
/// It is a drop-in replacement for the previous `Image.network(...)` calls:
/// pass the same `width`/`height`/`fit`, and hand the old `errorBuilder`/
/// `loadingBuilder` widgets in via [error] / [placeholder].
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Shown while the image downloads. Falls back to [error] then a light box.
  final Widget? placeholder;

  /// Shown when the image fails. Falls back to [placeholder] then a light box.
  final Widget? error;

  /// Explicit decode width cap. When null it is derived from [width] × the
  /// device pixel ratio (or a full-bleed default when width is unbounded).
  final int? cacheWidth;

  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.error,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: Color(0xFFF0E6D6));
    final ph = placeholder ?? error ?? fallback;
    final err = error ?? placeholder ?? fallback;

    if (url.isEmpty) return err;

    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
    final target = cacheWidth ??
        ((width != null && width!.isFinite)
            ? (width! * dpr).round().clamp(64, 2000)
            : 1080);

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: target,
      maxWidthDiskCache: target,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, __) => ph,
      errorWidget: (_, __, ___) => err,
    );
  }
}
