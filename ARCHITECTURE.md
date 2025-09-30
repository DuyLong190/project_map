# Kiến trúc Project Map Navigation

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                 # Entry point của ứng dụng
├── constants/
│   └── app_constants.dart   # Các hằng số và cấu hình
├── models/
│   ├── location_model.dart   # Model cho địa điểm
│   ├── route_model.dart      # Model cho đường đi
│   └── search_result_model.dart # Model cho kết quả tìm kiếm
├── services/
│   ├── location_service.dart # Service xử lý vị trí
│   ├── route_service.dart    # Service xử lý đường đi
│   └── search_service.dart   # Service tìm kiếm
├── providers/
│   └── map_provider.dart     # State management với Provider
├── screens/
│   └── map_screen.dart       # Màn hình chính
├── widgets/
│   ├── search_bar_widget.dart      # Widget thanh tìm kiếm
│   ├── search_results_widget.dart  # Widget kết quả tìm kiếm
│   ├── direction_controls_widget.dart # Widget điều khiển chỉ đường
│   └── location_info_widget.dart   # Widget thông tin vị trí
└── utils/                   # Các utility functions (tương lai)
```

## 🏗️ Kiến trúc Clean Architecture

### 1. **Models Layer**
- **Mục đích**: Định nghĩa cấu trúc dữ liệu
- **Files**: `lib/models/`
- **Chức năng**: 
  - `LocationModel`: Quản lý thông tin địa điểm
  - `RouteModel`: Quản lý thông tin đường đi
  - `SearchResultModel`: Quản lý kết quả tìm kiếm

### 2. **Services Layer**
- **Mục đích**: Xử lý logic nghiệp vụ và giao tiếp với API
- **Files**: `lib/services/`
- **Chức năng**:
  - `LocationService`: Lấy vị trí, địa chỉ, tính khoảng cách
  - `RouteService`: Lấy đường đi từ API, tính toán route
  - `SearchService`: Tìm kiếm địa điểm

### 3. **Providers Layer (State Management)**
- **Mục đích**: Quản lý state của ứng dụng
- **Files**: `lib/providers/`
- **Chức năng**:
  - `MapProvider`: Quản lý toàn bộ state của map, markers, routes

### 4. **UI Layer**
- **Screens**: `lib/screens/` - Các màn hình chính
- **Widgets**: `lib/widgets/` - Các component tái sử dụng
- **Constants**: `lib/constants/` - Các hằng số UI và cấu hình

## 🔄 Luồng dữ liệu

```
User Interaction → Screen → Provider → Service → API/Device
                ←        ←         ←        ←
```

### Ví dụ: Tìm kiếm địa điểm
1. **User** nhập text vào `SearchBarWidget`
2. **MapScreen** gọi `mapProvider.searchPlaces()`
3. **MapProvider** gọi `searchService.searchPlaces()`
4. **SearchService** gọi geocoding API
5. Kết quả trả về qua các layer và cập nhật UI

## 📦 Dependencies

### Core Flutter
- `flutter/material.dart`
- `provider` - State management

### Maps & Location
- `google_maps_flutter` - Hiển thị bản đồ
- `geolocator` - Lấy vị trí hiện tại
- `geocoding` - Chuyển đổi tọa độ ↔ địa chỉ

### Network
- `http` - Gọi API routing

### Permissions
- `permission_handler` - Quản lý quyền

## 🎯 Ưu điểm của kiến trúc mới

### 1. **Separation of Concerns**
- Mỗi layer có trách nhiệm riêng biệt
- Dễ test và debug
- Code dễ đọc và maintain

### 2. **Reusability**
- Widgets có thể tái sử dụng
- Services có thể dùng ở nhiều nơi
- Models có thể mở rộng dễ dàng

### 3. **Scalability**
- Dễ thêm features mới
- Có thể thay đổi state management
- API có thể thay đổi mà không ảnh hưởng UI

### 4. **Testability**
- Mỗi component có thể test độc lập
- Mock services dễ dàng
- Unit tests và integration tests

## 🚀 Cách thêm features mới

### Thêm tính năng mới (ví dụ: Lưu favorite locations)

1. **Model**: Tạo `FavoriteLocationModel`
2. **Service**: Thêm methods vào `LocationService` hoặc tạo `FavoriteService`
3. **Provider**: Thêm state và methods vào `MapProvider`
4. **Widget**: Tạo `FavoriteListWidget`
5. **Screen**: Thêm vào `MapScreen`

### Ví dụ code:
```dart
// 1. Model
class FavoriteLocationModel {
  final String id;
  final LocationModel location;
  final DateTime createdAt;
}

// 2. Service method
Future<void> saveFavorite(LocationModel location) async {
  // Save to local storage or API
}

// 3. Provider state
List<FavoriteLocationModel> _favorites = [];

// 4. Widget
class FavoriteListWidget extends StatelessWidget {
  // UI for favorite list
}
```

## 🔧 Configuration

### Constants
Tất cả các hằng số được tập trung trong `AppConstants`:
- Colors, sizes, durations
- API endpoints
- Error messages
- UI text

### Environment
- Development: Debug mode
- Production: Release mode với optimizations

## 📱 Platform Support

- **Android**: Đầy đủ tính năng
- **iOS**: Cần cấu hình thêm (Google Maps API key)
- **Web**: Có thể port với một số thay đổi

## 🔮 Roadmap

### Phase 1: Core Features ✅
- [x] Tìm kiếm địa điểm
- [x] Chỉ đường đi
- [x] Hiển thị vị trí hiện tại

### Phase 2: Enhanced Features
- [ ] Lưu favorite locations
- [ ] Lịch sử tìm kiếm
- [ ] Multiple route options
- [ ] Offline maps

### Phase 3: Advanced Features
- [ ] Real-time traffic
- [ ] Voice navigation
- [ ] Social features (share location)
- [ ] AR navigation

## 🐛 Debugging

### Common Issues
1. **API Errors**: Check network connectivity and API keys
2. **Permission Issues**: Verify location permissions in manifest
3. **State Issues**: Use Flutter Inspector to debug Provider state

### Logging
- Console logs for API calls
- Error handling with try-catch
- Debug prints for state changes

Kiến trúc này đảm bảo code dễ maintain, test và mở rộng trong tương lai! 🎉
