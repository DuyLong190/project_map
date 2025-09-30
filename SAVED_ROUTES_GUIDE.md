# 📍 Hướng dẫn sử dụng tính năng Lưu Vết

## 🎯 Tổng quan
Tính năng **Lưu Vết** cho phép bạn lưu lại các đường đi đã tìm kiếm để sử dụng lại sau này. Đây là tính năng rất hữu ích cho những tuyến đường bạn thường xuyên di chuyển.

## 🚀 Cách sử dụng

### 1. **Tìm đường đi**
- Chọn điểm xuất phát (nút xanh lá)
- Chọn điểm đến (nút đỏ)
- Nhấn "Tìm đường" để tìm đường đi

### 2. **Lưu vết**
- Sau khi đã tìm được đường đi
- Nhấn nút **"Lưu vết"** (màu xanh lá)
- Nhập tên vết (ví dụ: "Đi làm hàng ngày", "Đi học")
- Nhập mô tả (tùy chọn)
- Nhấn **"Lưu"**

### 3. **Xem vết đã lưu**
- Nhấn icon **bookmark** (🔖) ở góc phải trên cùng
- Danh sách các vết đã lưu sẽ hiển thị
- Có thể kéo lên/xuống để xem nhiều vết

### 4. **Sử dụng vết đã lưu**
- Tap vào vết muốn sử dụng
- Đường đi sẽ được tải lại trên bản đồ
- Có thể tìm đường mới hoặc điều chỉnh

### 5. **Quản lý vết**
- **Yêu thích**: Tap icon ❤️ để đánh dấu vết quan trọng
- **Xóa**: Tap icon 🗑️ để xóa vết không cần thiết
- **Xác nhận xóa**: Nhấn "Xóa" trong dialog xác nhận

## 📊 Thông tin hiển thị

### Mỗi vết hiển thị:
- **Tên vết**: Tên bạn đã đặt
- **Mô tả**: Thông tin bổ sung
- **Khoảng cách & thời gian**: Ví dụ "5.2 km • 15 phút"
- **Địa chỉ xuất phát**: Từ đâu
- **Địa chỉ đến**: Đến đâu
- **Ngày tạo**: Hôm nay, Hôm qua, hoặc ngày cụ thể

### Trạng thái vết:
- **Yêu thích**: ❤️ đỏ (vết quan trọng)
- **Bình thường**: ❤️ xám (vết thường)

## 🎨 Giao diện

### Nút "Lưu vết":
- Chỉ hiển thị khi có đường đi hoàn chỉnh
- Màu xanh lá, icon bookmark
- Nằm dưới các nút điều khiển chính

### Danh sách vết:
- Hiển thị trong bottom sheet
- Có thể kéo lên/xuống
- Mỗi vết là một card riêng biệt
- Tap để tải, long press để xem chi tiết

## 💾 Lưu trữ

### Dữ liệu được lưu:
- Tọa độ điểm xuất phát và đến
- Thông tin đường đi (khoảng cách, thời gian)
- Tên và mô tả vết
- Ngày tạo và lần truy cập cuối
- Trạng thái yêu thích

### Vị trí lưu trữ:
- Lưu trên thiết bị (SharedPreferences)
- Không cần kết nối internet
- Dữ liệu được mã hóa an toàn

## 🔧 Tính năng nâng cao

### Tìm kiếm vết:
- Có thể tìm theo tên vết
- Tìm theo địa chỉ xuất phát/đến
- Tìm trong mô tả

### Thống kê:
- Tổng số vết đã lưu
- Tổng khoảng cách đã di chuyển
- Vết cũ nhất và mới nhất

### Xuất/Nhập:
- Có thể xuất vết ra file JSON
- Nhập vết từ file khác
- Chia sẻ vết giữa các thiết bị

## ⚠️ Lưu ý quan trọng

1. **Giới hạn**: Không có giới hạn số lượng vết
2. **Bảo mật**: Dữ liệu chỉ lưu trên thiết bị
3. **Đồng bộ**: Không tự động đồng bộ giữa thiết bị
4. **Sao lưu**: Nên xuất định kỳ để tránh mất dữ liệu

## 🎯 Mẹo sử dụng

### Đặt tên vết có ý nghĩa:
- ✅ "Đi làm - Nhà đến công ty"
- ✅ "Đi học - Hàng ngày"
- ❌ "Vết 1", "Vết 2"

### Sử dụng mô tả:
- Ghi chú thời gian thường đi
- Lưu ý về giao thông
- Điều kiện đặc biệt

### Quản lý vết:
- Đánh dấu yêu thích những vết quan trọng
- Xóa định kỳ những vết không dùng
- Sắp xếp theo tần suất sử dụng

## 🆘 Xử lý sự cố

### Vết không hiển thị:
1. Kiểm tra kết nối internet
2. Restart ứng dụng
3. Kiểm tra quyền lưu trữ

### Không thể lưu vết:
1. Đảm bảo đã tìm được đường đi
2. Kiểm tra tên vết không trống
3. Restart ứng dụng

### Vết bị mất:
1. Kiểm tra cài đặt lưu trữ
2. Khôi phục từ sao lưu
3. Liên hệ hỗ trợ

---

**🎉 Chúc bạn sử dụng tính năng Lưu Vết hiệu quả!**
