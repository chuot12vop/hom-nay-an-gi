import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

import '../models/administrative_division.dart';
import '../models/food.dart';
import '../models/shared_restaurant.dart';
import '../models/sheet_data.dart';
import '../services/administrative_service.dart';
import '../services/google_sheet_service.dart';
import '../services/restaurant_storage_service.dart';
import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';
import 'map_picker_screen.dart';

/// Form để người dùng chia sẻ một quán ăn ngon: tên, mô tả, tỉnh/phường,
/// địa chỉ chi tiết và toạ độ chọn trên bản đồ.
class ShareRestaurantScreen extends StatefulWidget {
  const ShareRestaurantScreen({super.key});

  @override
  State<ShareRestaurantScreen> createState() => _ShareRestaurantScreenState();
}

class _ShareRestaurantScreenState extends State<ShareRestaurantScreen> {
  final AdministrativeService _adminService = AdministrativeService();
  final RestaurantStorageService _storage = RestaurantStorageService();
  final GoogleSheetService _sheetService = GoogleSheetService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _detailAddressController =
      TextEditingController();

  List<Province> _provinces = <Province>[];
  Province? _selectedProvince;
  Ward? _selectedWard;
  LatLng? _pickedLocation;

  List<Food> _foods = <Food>[];
  final List<String> _selectedFoodIds = <String>[];

  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final List<Province> provinces = await _adminService.loadProvinces();
      List<Food> foods = <Food>[];
      try {
        final SheetData data = await _sheetService.fetchAllTables();
        foods = List<Food>.from(data.foods)
          ..sort((Food a, Food b) => a.name.compareTo(b.name));
      } catch (_) {
        foods = <Food>[];
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _provinces = provinces;
        _foods = foods;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được dữ liệu tỉnh/thành')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final LatLng? result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => MapPickerScreen(initialLocation: _pickedLocation),
      ),
    );
    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_selectedProvince == null) {
      _snack('Vui lòng chọn Tỉnh/Thành phố');
      return;
    }
    if (_selectedWard == null) {
      _snack('Vui lòng chọn Phường/Xã');
      return;
    }
    if (_pickedLocation == null) {
      _snack('Vui lòng chọn vị trí trên bản đồ');
      return;
    }

    setState(() => _submitting = true);

    final Map<String, Food> foodById = <String, Food>{
      for (final Food f in _foods) f.id: f,
    };
    final List<Food> selectedFoods = _selectedFoodIds
        .map((String id) => foodById[id])
        .whereType<Food>()
        .toList();

    final SharedRestaurant entry = SharedRestaurant(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      provinceCode: _selectedProvince!.code,
      provinceName: _selectedProvince!.name,
      wardCode: _selectedWard!.code,
      wardName: _selectedWard!.name,
      detailAddress: _detailAddressController.text.trim(),
      latitude: _pickedLocation!.latitude,
      longitude: _pickedLocation!.longitude,
      createdAt: DateTime.now(),
      foodIds: selectedFoods.map((Food f) => f.id).toList(),
      foodNames: selectedFoods.map((Food f) => f.name).toList(),
    );

    try {
      await _storage.add(entry);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<bool>(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      _snack('Lưu không thành công, vui lòng thử lại');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: const Text('Chia sẻ quán ăn ngon'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _sectionTitle('Thông tin quán'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên quán *',
                              hintText: 'VD: Bún bò Huế O Xuân',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập tên quán';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Mô tả / món tủ',
                              hintText:
                                  'Quán đông, nên đi sớm. Món tủ: bún chả...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _sectionTitle('Món ăn'),
                          const SizedBox(height: 8),
                          if (_foods.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'Chưa tải được danh sách món ăn.',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          else
                            MultiDropdown<String>(
                              items: _foods
                                  .map(
                                    (Food food) => DropdownItem<String>(
                                      value: food.id,
                                      label: food.name,
                                      selected: _selectedFoodIds
                                          .contains(food.id),
                                    ),
                                  )
                                  .toList(),
                              fieldDecoration: const FieldDecoration(
                                hintText: 'Chọn món quán có',
                                prefixIcon:
                                    Icon(Icons.restaurant_menu_rounded),
                                suffixIcon: Icon(
                                    Icons.keyboard_arrow_down_rounded),
                              ),
                              searchEnabled: true,
                              searchDecoration: const SearchFieldDecoration(
                                hintText: 'Tìm món ăn',
                              ),
                              onSelectionChange: (List<String> values) {
                                _selectedFoodIds
                                  ..clear()
                                  ..addAll(values);
                              },
                            ),
                          const SizedBox(height: 20),
                          _sectionTitle('Địa chỉ'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Province>(
                            initialValue: _selectedProvince,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tỉnh / Thành phố *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city_rounded),
                            ),
                            items: _provinces
                                .map(
                                  (Province p) => DropdownMenuItem<Province>(
                                    value: p,
                                    child: Text(
                                      p.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (Province? value) {
                              setState(() {
                                _selectedProvince = value;
                                _selectedWard = null;
                              });
                            },
                            validator: (Province? value) => value == null
                                ? 'Vui lòng chọn Tỉnh/Thành'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Ward>(
                            initialValue: _selectedWard,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Phường / Xã *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.place_outlined),
                              enabled: _selectedProvince != null,
                              hintText: _selectedProvince == null
                                  ? 'Chọn Tỉnh/Thành trước'
                                  : null,
                            ),
                            items: (_selectedProvince?.wards ?? <Ward>[])
                                .map(
                                  (Ward w) => DropdownMenuItem<Ward>(
                                    value: w,
                                    child: Text(
                                      w.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _selectedProvince == null
                                ? null
                                : (Ward? value) =>
                                    setState(() => _selectedWard = value),
                            validator: (Ward? value) => value == null
                                ? 'Vui lòng chọn Phường/Xã'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _detailAddressController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Địa chỉ chi tiết *',
                              hintText: 'Số nhà, ngõ/hẻm, tên đường…',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.signpost_outlined),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập địa chỉ chi tiết';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Vị trí trên bản đồ'),
                          const SizedBox(height: 8),
                          _LocationPickerTile(
                            location: _pickedLocation,
                            onTap: _pickOnMap,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      child: Text(
                        _submitting ? 'Đang lưu...' : 'Chia sẻ quán ăn',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return GradientText(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _LocationPickerTile extends StatelessWidget {
  const _LocationPickerTile({
    required this.location,
    required this.onTap,
  });

  final LatLng? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = location != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation
                ? AppGradients.primaryMid
                : Colors.grey.shade400,
            width: hasLocation ? 1.5 : 1,
          ),
          color: hasLocation
              ? AppGradients.surfaceTint
              : Colors.grey.shade50,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              hasLocation ? Icons.place : Icons.add_location_alt_outlined,
              color: hasLocation
                  ? AppGradients.primaryEnd
                  : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hasLocation
                        ? 'Đã chọn vị trí'
                        : 'Chọn vị trí trên bản đồ *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasLocation
                        ? '${location!.latitude.toStringAsFixed(6)}, '
                            '${location!.longitude.toStringAsFixed(6)}'
                        : 'Chạm để mở bản đồ và thả ghim',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
