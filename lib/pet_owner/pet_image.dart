import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders a pet photo consistently across the app.
///
/// Photos are stored inline as base64 data URIs (`data:image/...;base64,...`)
/// in the pet record. When [photoUrl] is a data URI it is decoded and shown;
/// otherwise the provided [fallbackAsset] image is used. This keeps the home
/// carousel and the pet profile page visually in sync from one source.
class PetPhoto extends StatelessWidget {
  const PetPhoto({
    required this.photoUrl,
    required this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String photoUrl;
  final String fallbackAsset;
  final BoxFit fit;
  final Alignment alignment;

  static Uint8List? decodeDataUri(String value) {
    if (!value.startsWith('data:')) return null;
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataUri(photoUrl);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) =>
            Image.asset(fallbackAsset, fit: fit, alignment: alignment),
      );
    }
    return Image.asset(fallbackAsset, fit: fit, alignment: alignment);
  }
}
