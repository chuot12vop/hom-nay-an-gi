# Hôm Nay Ăn Gì - Luồng hệ thống

## 1) Tổng quan
App Flutter giúp người dùng lọc món ăn theo:
- Bữa ăn (sáng/trưa/tối)
- Giá tối đa
- Thành phần dị ứng

Dữ liệu món ăn được lấy từ Google Sheet, sau đó áp dụng bộ lọc và chuyển sang màn hình vòng quay để chọn món ngẫu nhiên.

## 2) Luồng chạy chính

1. **Khởi động app**
   - `main()` chạy `HomNayAnGiApp`.
   - Màn hình gốc là `BaseHomePage` với Bottom Navigation.
   - Tab mặc định là **Chọn món** (`_selectedIndex = 1`).

2. **Tải dữ liệu**
   - `ChooseFoodScreen.initState()` gọi `_loadData()`.
   - `_loadData()` lấy dữ liệu từ `GoogleSheetService.fetchAllTables()` gồm:
     - foods (gid=0)
     - categories (gid=1)
     - ingredients (gid=2)
     - meals (gid=3)
   - Nếu lỗi mạng / đọc sheet lỗi -> dùng dữ liệu fallback trong app.

3. **Khôi phục bộ lọc đã lưu**
   - Sau khi có dữ liệu, app đọc file local qua `FilterStorageService.read()`.
   - Nếu có bộ lọc cũ:
     - Gán lại `mealId`
     - Gán lại `maxPrice`
     - Gán lại danh sách `allergicIngredientIds`

4. **Người dùng chọn điều kiện lọc**
   - Chọn bữa ăn (Dropdown)
   - Chọn giá tối đa (Slider)
   - Chọn thành phần dị ứng (FilterChip)

5. **Xác nhận bộ lọc**
   - Bấm nút “Xác nhận bộ lọc và chuyển sang vòng quay”.
   - App tạo `SavedFilters` và lưu vào file `food_filters.json` trong Documents directory.
   - App đọc lại file vừa lưu để xác thực dữ liệu.

6. **Lọc danh sách món**
   - Hàm `_filterFoods()` áp dụng 3 điều kiện:
     - Nếu có `mealId` thì món phải cùng bữa ăn
     - `food.priceVnd <= maxPriceVnd`
     - Món không chứa nguyên liệu nằm trong `allergicIngredientIds`
   - Kết quả được trả lên `BaseHomePage` qua callback `onFoodsFiltered`.

7. **Chuyển sang vòng quay**
   - Nếu có món phù hợp, app gọi `onOpenWheelRequested()` để chuyển tab sang **Vòng quay** (`_selectedIndex = 2`).
   - `SpinWheelScreen` nhận danh sách món đã lọc và quay ngẫu nhiên trong tập đó.

8. **Vòng quay**
   - **Chạm vào vòng quay** (bánh) để quay; không còn nút riêng ở giữa.
   - Mũi tên cố định ở phía trên (12h); sau khi dừng, **ô nằm dưới mũi tên** trùng với **món hiển thị** ở dưới (góc dừng được tính bù theo góc hiện tại sau mỗi lượt quay).

## 3) Thành phần chính

- `lib/main.dart`
  - Điều hướng tab chính, truyền dữ liệu món đã lọc từ tab Chọn món sang tab Vòng quay.
- `lib/screens/choose_food_screen.dart`
  - UI chọn bộ lọc + tải dữ liệu + lọc món + điều hướng sang vòng quay.
- `lib/screens/spin_wheel_screen.dart`
  - Vòng quay: animation quay, chọn món theo ô dưới mũi tên sau khi dừng.
- `lib/services/google_sheet_service.dart`
  - Đọc CSV từ Google Sheet, map về model (`Food`, `Meal`, `Ingredient`, `FoodCategory`).
- `lib/services/filter_storage_service.dart`
  - Lưu/đọc bộ lọc JSON ở local (`food_filters.json`).

## 4) Dữ liệu vào/ra

- **Input từ Google Sheet**: CSV export theo từng `gid`.
- **Input từ người dùng**: meal, max price, dị ứng.
- **Local persistence**: `food_filters.json`.
- **Output**: danh sách món phù hợp để quay ngẫu nhiên.