# Hôm Nay Ăn Gì — Luồng hệ thống

## 1) Tổng quan

Ứng dụng **Flutter** (`app-flutter/`) giúp chọn món, quay ngẫu nhiên để "định đoạt số phận" bữa ăn, xem **lịch sử các lần quay trúng**, xem **video YouTube ngắn** và **chia sẻ quán ăn ngon** (kèm vị trí trên bản đồ) để gợi ý cho chính mình hoặc mọi người khi ra quán.

Dữ liệu món, nguyên liệu, bữa ăn và danh sách video được đọc từ Google Sheet (CSV export). Khi lỗi mạng hoặc đọc sheet thất bại, app dùng dữ liệu fallback tích hợp sẵn.

Dữ liệu địa chính (34 tỉnh/thành sau sáp nhập 2025) được đọc từ `assets/json/dia_chinh_34.json`.

**Tên package Dart** (import trong test / package): `hom_nay_an_gi` — xem `app-flutter/pubspec.yaml`.

## 2) Thanh điều hướng (Bottom Navigation)

`BaseHomePage` dùng `IndexedStack`; **tab mặc định là Quán ăn** (`selectedIndex = 1`). Khung **Scaffold** (AppBar gradient, bottom nav) do `BaseHomeShell` render; nội dung tab do `BaseHomePage` ghép.

| Index | Nhãn       | Màn hình / nội dung |
|-------|------------|----------------------|
| 0     | Lịch sử    | `HistoryScreen` — các lần quay trúng (mới nhất trước), bấm vào món để mở chi tiết |
| 1     | Quán ăn    | `RestaurantListScreen` — danh sách quán do người dùng chia sẻ cục bộ + FAB mở form chia sẻ |
| 2     | Vòng quay  | `SpinWheelScreen` — quay chọn món; sau khi quay trúng có thể mở màn gợi ý quán |
| 3     | Video      | `ShortVideosScreen` — vuốt dọc xem short YouTube từ sheet |
| 4     | Tài khoản  | Placeholder (chưa triển khai) |

**Rời tab Vòng quay** (chuyển sang tab khác): xóa danh sách món đã lọc và tăng `wheelSession` để tạo lại state vòng quay (key mới).

> Ghi chú: `ChooseFoodScreen` (bộ lọc bữa / giá / dị ứng) vẫn còn trong `lib/screens/` nhưng hiện **không được gắn vào bottom nav**. Vòng quay hiện chỉ dùng `defaultWheelFoods` từ lịch sử. Có thể tái gắn sau nếu muốn khôi phục luồng lọc.

## 3) Luồng chạy chính

### 3.1 Khởi động

- `main()` trong `lib/main.dart` gọi `runApp(const HomNayAnGiApp())`.
- `HomNayAnGiApp` (`lib/app.dart`) bọc `MaterialApp` với theme từ `buildAppTheme()` (`lib/theme/app_theme.dart`), `home: BaseHomePage`.
- `BaseHomeController.loadDefaultWheelFoods()`: tải `SheetData` qua `GoogleSheetService.fetchAllTables()`, lấy tối đa **10 `food_id` khác nhau** từ lịch sử quay gần nhất (`SpinHistoryService.recentUniqueFoodIds(10)`), map sang `Food` để dùng làm **mặc định cho vòng quay**.

### 3.2 Tab Quán ăn — chia sẻ quán

- `RestaurantListScreen` đọc `shared_restaurants.json` (thư mục Documents của app) qua `RestaurantStorageService`. Hiển thị card từng quán: tên, mô tả, chip món quán có, địa chỉ đầy đủ, toạ độ, thời gian chia sẻ. **Long-press** để xoá.
- FAB **"Chia sẻ quán"** mở `ShareRestaurantScreen`.
- `ShareRestaurantScreen` (form):
  - Tên quán, mô tả.
  - **Món ăn** — `MultiDropdown` có tìm kiếm, nguồn là `SheetData.foods` (dùng lại cache phiên).
  - Dropdown **Tỉnh/Thành phố** và **Phường/Xã** — nguồn `AdministrativeService` đọc `assets/json/dia_chinh_34.json`.
  - **Địa chỉ chi tiết** (ô text).
  - Nút **"Chọn vị trí trên bản đồ"** mở `MapPickerScreen` (OSM tile qua `flutter_map`). Mở màn sẽ tự **lấy GPS và thả ghim** tại vị trí hiện tại; user có thể chạm bản đồ để đổi ghim, hoặc bấm nút "Vị trí của tôi" để quay lại GPS hiện tại.
  - Submit: lưu `SharedRestaurant` (gồm `foodIds`, `foodNames`, `provinceCode`, `wardCode`, `latitude`, `longitude`, …) qua `RestaurantStorageService.add()`.

### 3.3 Tab Vòng quay

- **Nguồn món trên bánh**: `filteredFoods` nếu có (từ luồng lọc — hiện không gắn nav), ngược lại dùng `defaultWheelFoods` (từ lịch sử). Trong lúc tải: `isLoadingDefaultFoods` bật loading phù hợp.
- Sau mỗi lần quay xong: `onSpinCompleted` → `SpinHistoryService.appendSpin(food)`, tăng `historyVersion` (làm mới tab Lịch sử), gọi lại `loadDefaultWheelFoods(silent: true)` để cập nhật danh sách mặc định không che UI vòng quay.
- Sau khi trúng món, hiển thị các lựa chọn:
  - **Quay xe** — quay lại luồng chọn món.
  - **Đi ăn ngoài** / **Đặt đồ về ăn tại nhà** — mở `RestaurantSuggestionsScreen(food: winner)` (xem 3.4).
  - **Tự nấu** — mở `FoodDetailScreen` (nếu món có `recipeUrl` hợp lệ).

### 3.4 Gợi ý quán theo món (`RestaurantSuggestionsScreen`)

- Đọc toàn bộ quán từ `RestaurantStorageService`, lọc theo `foodIds.contains(food.id)`.
- Lấy vị trí người dùng: ưu tiên `UserLocationService.refreshAndPersist()` (GPS + quyền), fallback `readSaved()` (đã lưu).
- Với mỗi quán, tính khoảng cách bằng `Geolocator.distanceBetween(userLat, userLng, r.lat, r.lng)` (mét).
- **Sắp xếp theo khoảng cách tăng dần** (quán gần nhất lên đầu); quán chưa xác định được khoảng cách bị đẩy xuống cuối.
- Banner nhắc bật GPS nếu chưa có vị trí; empty state + CTA mở form chia sẻ quán khi chưa có quán nào phục vụ món.

### 3.5 Tab Video

- Dữ liệu `shortVideos` từ cùng `SheetData`. Chỉ phát khi tab Video đang active (`isActiveTab`); rời tab thì hủy controller để tránh phát nền.

## 4) Google Sheet — nguồn dữ liệu

- **Sheet ID mặc định** (trong `GoogleSheetService`): `1VoJ-5oiBt0YKPuAwUFDKaleNS8OofHGEed5Rurmoscc`.
- **CSV export** theo `gid` (không còn tải bảng "categories" riêng; `category_ids` nằm trong hàng món).

| Nội dung   | Biến trong code   | `gid`      |
|------------|-------------------|------------|
| Món        | `foodsGid`        | `93052399` |
| Nguyên liệu| `ingredientsGid`  | `1896529337` |
| Bữa ăn     | `mealsGid`        | `1084511461` |
| Video ngắn | `videosGid`       | `974384037` |

- Tab video nếu lỗi được bỏ qua (danh sách rỗng), không làm fail toàn bộ tải.
- Giải mã CSV UTF-8 (xử lý BOM) để tránh lỗi font tiếng Việt.

## 5) Lưu trữ cục bộ

| File                      | Mục đích |
|---------------------------|----------|
| `food_filters.json`       | Bộ lọc đã xác nhận (`FilterStorageService`) |
| `spin_history.json`       | Lịch sử quay trúng, tối đa 500 bản ghi (`SpinHistoryService`) |
| `shared_restaurants.json` | Quán ăn người dùng chia sẻ (`RestaurantStorageService`) |
| `SharedPreferences` (key `user_latitude` / `user_longitude`) | Vị trí người dùng lần gần nhất (`UserLocationService`) |

## 6) Assets

- `assets/image/logoApp.png` — logo app.
- `assets/json/dia_chinh_34.json` — 34 tỉnh/thành + phường/xã (cấu trúc sau sáp nhập 2025). Dùng bởi `AdministrativeService`.
- `assets/json/dia_chinh_63.json` — 63 tỉnh cũ (lưu trữ, hiện chưa dùng).

## 7) Thành phần chính (mã nguồn)

### Điểm vào & theme

- `app-flutter/lib/main.dart` — `runApp(const HomNayAnGiApp())`.
- `app-flutter/lib/app.dart` — `HomNayAnGiApp`, `MaterialApp`.
- `app-flutter/lib/theme/app_theme.dart` — `buildAppTheme()`.
- `app-flutter/lib/theme/app_gradients.dart` — màu / gradient dùng chung.

### Shell & điều phối tab

- `app-flutter/lib/controllers/base_home_controller.dart` — `BaseHomeController` (`ChangeNotifier`): state và luồng tab / vòng quay / lịch sử; inject `fetchSheetData` / `SpinHistoryService` để unit test.
- `app-flutter/lib/screens/base_home_page.dart` — `BaseHomePage`: `IndexedStack`, nối `BaseHomeController` với các màn con.
- `app-flutter/lib/widgets/base_home_shell.dart` — `BaseHomeShell`: Scaffold (AppBar + bottom nav).

### Màn hình

- `app-flutter/lib/screens/restaurant_list_screen.dart` — Tab "Quán ăn": list quán đã chia sẻ + FAB mở form.
- `app-flutter/lib/screens/share_restaurant_screen.dart` — Form chia sẻ quán: tên, mô tả, món (MultiDropdown), tỉnh/phường, địa chỉ chi tiết, chọn vị trí bản đồ.
- `app-flutter/lib/screens/map_picker_screen.dart` — Map picker OSM (flutter_map), tự động lấy GPS khi mở.
- `app-flutter/lib/screens/restaurant_suggestions_screen.dart` — Gợi ý quán cho món đã quay, sắp theo khoảng cách.
- `app-flutter/lib/screens/spin_wheel_screen.dart` — Vòng quay + các CTA sau khi trúng (Đi ăn ngoài / Đặt về / Tự nấu).
- `app-flutter/lib/screens/history_screen.dart` — Lịch sử quay; điều hướng `FoodDetailScreen` khi có dữ liệu món.
- `app-flutter/lib/screens/food_detail_screen.dart` — Chi tiết món (ảnh, công thức WebView, YouTube nếu có).
- `app-flutter/lib/screens/short_videos_screen.dart` — Feed video dọc (YouTube).
- `app-flutter/lib/screens/choose_food_screen.dart` — Bộ lọc (bữa / giá / dị ứng). **Hiện không gắn bottom nav**; giữ lại để có thể tái dùng.

### Dịch vụ

- `app-flutter/lib/services/google_sheet_service.dart` — HTTP CSV, map model, cache phiên, fallback.
- `app-flutter/lib/services/filter_storage_service.dart` — `food_filters.json`.
- `app-flutter/lib/services/spin_history_service.dart` — `spin_history.json`.
- `app-flutter/lib/services/restaurant_storage_service.dart` — `shared_restaurants.json`.
- `app-flutter/lib/services/administrative_service.dart` — parse `assets/json/dia_chinh_34.json` thành `Province` + `Ward` (cache phiên).
- `app-flutter/lib/services/user_location_service.dart` — lấy + lưu vị trí người dùng (geolocator + shared_preferences).
- `app-flutter/lib/services/youtube_oembed_service.dart` — metadata / ảnh bìa cho player.
- `app-flutter/lib/services/common_service.dart` — định dạng số theo locale (`intl`).

### Model

- `app-flutter/lib/models/sheet_data.dart` — `SheetData` (gộp list món, nguyên liệu, bữa, video).
- `app-flutter/lib/models/food.dart`, `ingredient.dart`, `meal.dart`, `sheet_short_video.dart`, `saved_filters.dart` — entity sheet.
- `app-flutter/lib/models/shared_restaurant.dart` — quán người dùng chia sẻ (gồm `foodIds` / `foodNames`, province/ward, lat/lng).
- `app-flutter/lib/models/administrative_division.dart` — `Province`, `Ward`.

### Widget & tiện ích

- `app-flutter/lib/widgets/app_gradient_bottom_nav.dart` — bottom navigation gradient.
- `app-flutter/lib/widgets/gradient_widgets.dart` — AppBar gradient, text gradient, button gradient.
- `app-flutter/lib/widgets/youtube_cover_player.dart` — player phủ thumbnail.
- `app-flutter/lib/widgets/search_dropdown_multi_select.dart` — chọn nhiều.
- `app-flutter/lib/utils/youtube_video_id.dart` — trích ID từ URL YouTube.

## 8) Dependencies chính (pubspec)

- UI / đa nền tảng: `flutter`, `cupertino_icons`, `intl`.
- Dữ liệu sheet: `http`, `csv`.
- Lưu trữ: `path_provider`, `shared_preferences`.
- Video: `youtube_player_flutter`, `webview_flutter`.
- Dropdown tìm kiếm: `multi_dropdown`.
- **Bản đồ & vị trí**: `flutter_map` (OSM, không cần API key), `latlong2`, `geolocator`.

## 9) Chạy dự án

```bash
cd app-flutter
flutter pub get
flutter run
```

(Yêu cầu Flutter SDK tương thích `environment.sdk` trong `pubspec.yaml`.)

Chạy test widget:

```bash
cd app-flutter
flutter test
```

## 10) Dữ liệu vào / ra (tóm tắt)

- **Đầu vào từ sheet**: CSV theo các `gid` ở mục 4; cột món gồm `food_id`, `food_name_vi` / `name`, `meal_ids`, `price_vnd`, `ingredient_ids`, `category_ids`, …; video short: `url`, `thumbnail`, `category`, `food_id`, `meal_id`, …
- **Đầu vào người dùng**:
  - Bữa / giá tối đa / nguyên liệu dị ứng (khi còn dùng luồng bộ lọc).
  - Form chia sẻ quán: tên, mô tả, món, tỉnh/phường, địa chỉ chi tiết, vị trí chọn trên map.
  - Vị trí GPS (cho gợi ý quán theo khoảng cách).
- **Đầu ra**:
  - Lần quay trúng ghi vào lịch sử.
  - Quán ăn lưu cục bộ (`shared_restaurants.json`).
  - Sau khi quay trúng món: danh sách quán gợi ý được sắp theo khoảng cách tới người dùng.
