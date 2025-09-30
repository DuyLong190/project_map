import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Map Navigation';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String osrmBaseUrl = 'http://router.project-osrm.org';
  static const int maxSearchResults = 5;
  static const int apiTimeoutSeconds = 30;

  // Map Configuration
  static const double defaultZoom = 15.0;
  static const double routeZoom = 12.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 3.0;
  static const double cameraPadding = 100.0;

  // Route Configuration
  static const double routeLineWidth = 5.0;
  static const double minimumRouteDistanceMeters = 100.0;
  static const int estimatedSpeedKmh = 30; // For time estimation

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Marker Colors
  static const Color currentLocationColor = Color(0xFF2196F3);
  static const Color startLocationColor = Color(0xFF4CAF50);
  static const Color endLocationColor = Color(0xFFF44336);
  static const Color selectedLocationColor = Color(0xFF9C27B0);

  // Route Colors
  static const Color routeColor = Color(0xFF2196F3);
  static const Color estimatedRouteColor = Color(0xFFFF9800);

  // Animation Duration
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle bodyStyle = TextStyle(fontSize: 16);

  // Error Messages
  static const String locationPermissionDenied =
      'Quyền truy cập vị trí bị từ chối';
  static const String locationServiceDisabled = 'Dịch vụ vị trí bị tắt';
  static const String networkError = 'Lỗi kết nối mạng';
  static const String routeNotFound = 'Không tìm thấy đường đi';
  static const String searchError = 'Lỗi khi tìm kiếm';
  static const String unknownError = 'Đã xảy ra lỗi không xác định';

  // Success Messages
  static const String routeFound = 'Đã tìm thấy đường đi';
  static const String locationUpdated = 'Đã cập nhật vị trí';
  static const String searchCompleted = 'Tìm kiếm hoàn tất';

  // Placeholder Text
  static const String searchHint = 'Nhập địa điểm cần tìm...';
  static const String loadingText = 'Đang tải...';
  static const String noResultsText = 'Không tìm thấy kết quả';

  // Button Labels
  static const String searchButton = 'Tìm';
  static const String getCurrentLocationButton = 'Lấy vị trí hiện tại';
  static const String setStartButton = 'Điểm xuất phát';
  static const String setEndButton = 'Điểm đến';
  static const String findRouteButton = 'Tìm đường';
  static const String clearRouteButton = 'Xóa đường';
  static const String saveRouteButton = 'Lưu vết';
  static const String loadRouteButton = 'Tải vết';
  static const String deleteRouteButton = 'Xóa';
  static const String favoriteRouteButton = 'Yêu thích';

  // Section Titles
  static const String currentLocationTitle = 'VỊ TRÍ HIỆN TẠI';
  static const String selectedLocationTitle = 'VỊ TRÍ ĐƯỢC CHỌN';
  static const String searchResultsTitle = 'KẾT QUẢ TÌM KIẾM';
  static const String directionTitle = 'CHỈ ĐƯỜNG';
  static const String savedRoutesTitle = 'VẾT ĐÃ LƯU';
  static const String favoriteRoutesTitle = 'VẾT YÊU THÍCH';

  // Save Route Dialog
  static const String saveRouteTitle = 'Lưu vết đường đi';
  static const String routeNameHint = 'Tên vết (ví dụ: Đi làm hàng ngày)';
  static const String routeDescriptionHint = 'Mô tả (tùy chọn)';
  static const String saveButton = 'Lưu';
  static const String cancelButton = 'Hủy';

  // Messages
  static const String routeSavedSuccess = 'Đã lưu vết thành công!';
  static const String routeDeletedSuccess = 'Đã xóa vết!';
  static const String routeLoadedSuccess = 'Đã tải vết!';
  static const String noSavedRoutes = 'Chưa có vết nào được lưu';
  static const String confirmDeleteRoute = 'Bạn có chắc muốn xóa vết này?';
}
