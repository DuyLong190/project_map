import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

mixin MouseWheelZoomMixin<T extends StatefulWidget> on State<T> {
  GoogleMapController? get mapController;

  /// Gọi trong `Listener.onPointerSignal`
  void onPointerSignal(PointerSignalEvent event) {
    if (mapController == null) return;
    if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy;
      _handleZoom(delta);
    }
  }

  Future<void> _handleZoom(double delta) async {
    try {
      // Lấy zoom hiện tại
      final zoomLevel = await mapController!.getZoomLevel();

      // Giới hạn zoom (Google Maps API: 2 → 21)
      double newZoom = zoomLevel;
      if (delta > 0) {
        newZoom = (zoomLevel - 0.3).clamp(2.0, 21.0);
      } else {
        newZoom = (zoomLevel + 0.3).clamp(2.0, 21.0);
      }

      // Lấy camera hiện tại
      final pos = await mapController!.getLatLng(
        ScreenCoordinate(x: 0, y: 0),
      );

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: newZoom),
        ),
      );
    } catch (_) {
      // bỏ qua lỗi nhỏ (VD: chưa có mapController)
    }
  }
}
