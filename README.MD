# Hôm Nay Ăn Gì — Luồng hệ thống

## 1) Tổng quan

Ứng dụng **Flutter** (`app-flutter/`) giúp chọn món theo bộ lọc (bữa ăn, giá tối đa, dị ứng), quay ngẫu nhiên trong tập món phù hợp, xem **lịch sử các lần quay trúng**, và xem **video YouTube ngắn** lấy từ Google Sheet.

Dữ liệu món, nguyên liệu, bữa ăn và danh sách video được đọc từ Google Sheet (CSV export). Khi lỗi mạng hoặc đọc sheet thất bại, app dùng dữ liệu fallback tích hợp sẵn.

## 2) Thanh điều hướng (Bottom Navigation)

`BaseHomePage` dùng `IndexedStack`; **tab mặc định là Gọi món** (`_selectedIndex = 1`).

| Index | Nhãn       | Màn hình / nội dung |
|-------|------------|----------------------|
| 0     | Lịch sử    | `HistoryScreen` — các lần quay trúng (mới nhất trước), bấm vào món để mở chi tiết |
| 1     | Gọi món    | `ChooseFoodScreen` — bộ lọc + tải sheet + lọc món |
| 2     | Vòng quay  | `SpinWheelScreen` — quay chọn món |
| 3     | Video      | `ShortVideosScreen` — vuốt dọc xem short YouTube từ sheet |
| 4     | Tài khoản  | Placeholder (chưa triển khai) |

**Rời tab Vòng quay** (chuyển sang tab khác): xóa danh sách món đã lọc từ Gọi món và tăng `_wheelSession` để tạo lại state vòng quay (key mới).

## 3) Luồng chạy chính

### 3.1 Khởi động

- `main()` chạy `HomNayAnGiApp` → `BaseHomePage`.
- `BaseHomePage` gọi `_loadDefaultWheelFoods()`: tải `SheetData` qua `GoogleSheetService.fetchAllTables()`, lấy tối đa **10 `food_id` khác nhau** từ lịch sử quay gần nhất (`SpinHistoryService.recentUniqueFoodIds(10)`), map sang `Food` để dùng làm **mặc định cho vòng quay** khi người dùng chưa lọc từ tab Gọi món.

### 3.2 Tab Gọi món — tải dữ liệu và bộ lọc

- `ChooseFoodScreen.initState()` → `_loadData()`.
- `fetchAllTables()` trả về `foods`, `ingredients`, `meals`, `shortVideos` (xem mục 5). Có **cache phiên**: lần đầu gọi mạng, các lần sau dùng lại dữ liệu trong bộ nhớ.
- Sau khi có dữ liệu: `FilterStorageService.read()` khôi phục `mealId`, `maxPrice`, `allergicIngredientIds` nếu đã lưu.
- Slider giá được giới hạn theo min/max giá thực tế trong danh sách món (`_applyPriceBoundsFromFoods`).

### 3.3 Xác nhận bộ lọc

- Bấm nút xác nhận → tạo `SavedFilters`, ghi `food_filters.json` (thư mục Documents của app), đọc lại để xác thực.
- `_filterFoods()`: lọc theo bữa (nếu chọn), `priceVnd <= maxPrice`, loại món chứa nguyên liệu dị ứng.
- Kết quả gửi lên `BaseHomePage` qua `onFoodsFiltered`. Có thể gọi `onOpenWheelRequested()` để chuyển sang tab **Vòng quay** (`_selectedIndex = 2`).

### 3.4 Tab Vòng quay

- **Nguồn món trên bánh**: nếu đã lọc từ Gọi món thì dùng `_filteredFoods`; nếu rỗng thì dùng `_defaultWheelFoods` (từ lịch sử, đã nạp ở bước 3.1). Trong lúc tải mặc định: `isLoadingDefaultFoods` bật trạng thái loading phù hợp.
- Sau mỗi lần quay xong: `onSpinCompleted` → `SpinHistoryService.appendSpin(food)`, tăng `_historyVersion` (làm mới tab Lịch sử), `_loadDefaultWheelFoods(silent: true)` để cập nhật danh sách mặc định không che UI vòng quay.
- Chạm vào bánh để quay; mũi tên cố định; góc dừng được tính để ô dưới mũi tên khớp món hiển thị.

### 3.5 Tab Video

- Dữ liệu `shortVideos` từ cùng `SheetData`. Chỉ phát khi tab Video đang active (`isActiveTab`); rời tab thì hủy controller để tránh phát nền.

## 4) Google Sheet — nguồn dữ liệu

- **Sheet ID mặc định** (trong `GoogleSheetService`): `1VoJ-5oiBt0YKPuAwUFDKaleNS8OofHGEed5Rurmoscc`.
- **CSV export** theo `gid` (không còn tải bảng “categories” riêng; `category_ids` nằm trong hàng món):

| Nội dung   | Biến trong code   | `gid`      |
|------------|-------------------|------------|
| Món        | `foodsGid`        | `93052399` |
| Nguyên liệu| `ingredientsGid`  | `1896529337` |
| Bữa ăn     | `mealsGid`        | `1084511461` |
| Video ngắn | `videosGid`       | `974384037` |

- Tab video nếu lỗi được bỏ qua (danh sách rỗng), không làm fail toàn bộ tải.
- Giải mã CSV UTF-8 (xử lý BOM) để tránh lỗi font tiếng Việt.

## 5) Lưu trữ cục bộ

| File               | Mục đích |
|--------------------|----------|
| `food_filters.json`| Bộ lọc đã xác nhận (`FilterStorageService`) |
| `spin_history.json`| Lịch sử quay trúng, tối đa 500 bản ghi (`SpinHistoryService`) |

## 6) Thành phần chính (mã nguồn)

- `app-flutter/lib/main.dart` — `HomNayAnGiApp`, `BaseHomePage`, điều phối tab, state món lọc / vòng quay / lịch sử.
- `app-flutter/lib/screens/choose_food_screen.dart` — Gọi món: bộ lọc, lưu/khôi phục filter.
- `app-flutter/lib/screens/spin_wheel_screen.dart` — Vòng quay.
- `app-flutter/lib/screens/history_screen.dart` — Lịch sử quay; điều hướng `FoodDetailScreen` khi có dữ liệu món từ sheet.
- `app-flutter/lib/screens/short_videos_screen.dart` — Feed video dọc (YouTube).
- `app-flutter/lib/screens/food_detail_screen.dart` — Chi tiết món (ảnh, công thức WebView, YouTube nếu có).
- `app-flutter/lib/services/google_sheet_service.dart` — HTTP CSV, map model, cache phiên, fallback.
- `app-flutter/lib/services/filter_storage_service.dart` — `food_filters.json`.
- `app-flutter/lib/services/spin_history_service.dart` — `spin_history.json`.
- `app-flutter/lib/services/youtube_oembed_service.dart` — Hỗ trợ metadata/ảnh bìa cho player (nếu được gọi từ UI video).
- `app-flutter/lib/models/sheet_data.dart` — `Food`, `Ingredient`, `Meal`, `SheetShortVideo`.

## 7) Chạy dự án

```bash
cd app-flutter
flutter pub get
flutter run
```

(Yêu cầu Flutter SDK tương thích `environment.sdk` trong `pubspec.yaml`.)

## 8) Dữ liệu vào / ra (tóm tắt)

- **Đầu vào từ sheet**: CSV theo các `gid` ở mục 4; cột món gồm `food_id`, `food_name_vi` / `name`, `meal_ids`, `price_vnd`, `ingredient_ids`, `category_ids`, v.v.; video short: `url`, `thumbnail`, `category`, `food_id`, `meal_id`, …
- **Đầu vào người dùng**: bữa, giá tối đa, nguyên liệu dị ứng.
- **Đầu ra**: danh sách món lọc được; lần quay trúng ghi vào lịch sử; UI chi tiết và video theo dữ liệu sheet.
