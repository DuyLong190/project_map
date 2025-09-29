# Hướng dẫn sử dụng ứng dụng Maps với chức năng chỉ đường

## 🗺️ Chức năng đã có:

### 1. **Tìm kiếm địa điểm**
- Nhập tên địa điểm vào ô tìm kiếm (ví dụ: "Hồ Gươm", "Bến Thành", "Chợ Bến Thành")
- Nhấn nút "Tìm" hoặc Enter
- Chọn từ danh sách kết quả để di chuyển đến vị trí đó

### 2. **Chỉ đường đi (Direction)**
- **Bước 1**: Tap vào vị trí trên bản đồ hoặc tìm kiếm địa điểm đầu tiên
- **Bước 2**: Nhấn nút "Điểm xuất phát" (màu xanh lá)
- **Bước 3**: Tap vào vị trí khác hoặc tìm kiếm địa điểm thứ hai
- **Bước 4**: Nhấn nút "Điểm đến" (màu đỏ)
- **Bước 5**: Nhấn nút "Tìm đường" (màu xanh dương)

## 🎯 Cách test chức năng chỉ đường:

### **Phương pháp 1: Tap trực tiếp trên bản đồ**
1. Mở ứng dụng
2. Chờ bản đồ load và hiển thị vị trí hiện tại
3. Tap vào một vị trí trên bản đồ (không phải vị trí hiện tại)
4. Nhấn nút "Điểm xuất phát" (xanh lá)
5. Tap vào vị trí khác trên bản đồ
6. Nhấn nút "Điểm đến" (đỏ)
7. Nhấn nút "Tìm đường" (xanh dương)

### **Phương pháp 2: Kết hợp tìm kiếm**
1. Tìm kiếm địa điểm đầu tiên (ví dụ: "Hồ Gươm")
2. Chọn từ danh sách kết quả
3. Nhấn nút "Điểm xuất phát"
4. Tìm kiếm địa điểm thứ hai (ví dụ: "Bến Thành")
5. Chọn từ danh sách kết quả
6. Nhấn nút "Điểm đến"
7. Nhấn nút "Tìm đường"

## 🔍 Các dấu hiệu thành công:

### **Markers (Điểm đánh dấu):**
- 🔵 **Xanh dương**: Vị trí hiện tại của bạn
- 🟢 **Xanh lá**: Điểm xuất phát
- 🔴 **Đỏ**: Điểm đến

### **Route (Đường đi):**
- **Đường xanh dương**: Đường đi thực tế từ API OSRM
- **Đường cam đứt nét**: Đường thẳng ước tính (khi API không khả dụng)

### **Thông tin Route:**
- **Khoảng cách**: Hiển thị bằng km
- **Thời gian**: Hiển thị bằng phút
- **Camera**: Tự động zoom để hiển thị toàn bộ route

## 🛠️ Troubleshooting:

### **Nếu không hiển thị đường đi:**
1. Kiểm tra kết nối internet
2. Đảm bảo đã chọn đủ 2 điểm (xuất phát và đến)
3. Xem console log để kiểm tra lỗi API
4. Nếu API OSRM không hoạt động, sẽ tự động hiển thị đường thẳng ước tính

### **Nếu markers không hiển thị:**
1. Đảm bảo đã cho phép quyền vị trí
2. Chờ bản đồ load hoàn toàn
3. Thử tap vào vị trí khác trên bản đồ

## 📱 Tính năng bổ sung:

- **Xóa đường**: Nhấn nút "Xóa đường" (cam) để xóa route hiện tại
- **Lấy vị trí hiện tại**: Nhấn nút "Lấy vị trí hiện tại" để quay về vị trí của bạn
- **Auto-fit**: Camera tự động điều chỉnh để hiển thị toàn bộ route
- **Real-time**: Cập nhật thông tin theo thời gian thực

## 🌐 API được sử dụng:

- **OSRM API**: Miễn phí, open source cho routing
- **Geocoding**: Để tìm kiếm địa điểm
- **Geolocator**: Để lấy vị trí hiện tại
- **Google Maps**: Để hiển thị bản đồ

Chúc bạn sử dụng ứng dụng thành công! 🎉
