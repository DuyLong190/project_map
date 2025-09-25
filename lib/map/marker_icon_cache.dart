import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconCache {
  MarkerIconCache._();

  static final MarkerIconCache instance = MarkerIconCache._();

  final Map<String, BitmapDescriptor> _descriptorCache = {};
  final Map<String, Future<BitmapDescriptor>> _inflight = {};

  BitmapDescriptor defaultHue(double hue) {
    final key = 'default:$hue';
    final cached = _descriptorCache[key];
    if (cached != null) return cached;
    final created = BitmapDescriptor.defaultMarkerWithHue(hue);
    _descriptorCache[key] = created;
    return created;
  }

  Future<BitmapDescriptor> fromAsset(String assetPath,{int targetWidth = 96}) {
    final key = 'asset:$assetPath:$targetWidth';
    final cached = _descriptorCache[key];
    if (cached != null) return SynchronousFuture(cached);
    final inflight = _inflight[key];
    if (inflight != null) return inflight;
    final future = _loadAndResizeAsset(assetPath, targetWidth).then((bd) {
      _descriptorCache[key] = bd;
      _inflight.remove(key);
      return bd;
    }).catchError((e) {
      _inflight.remove(key);
      // Fallback to default marker to avoid crashes due to decoding issues
      final fallback = BitmapDescriptor.defaultMarker;
      _descriptorCache[key] = fallback;
      return fallback;
    });
    _inflight[key] = future;
    return future;
  }

  Future<BitmapDescriptor> _loadAndResizeAsset(String assetPath, int targetWidth) async {
    final bytes = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(),
      targetWidth: targetWidth,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return BitmapDescriptor.defaultMarker;
    }
    final resized = data.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resized);
  }
}


