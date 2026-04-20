import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/food.dart';
import '../models/sheet_data.dart';
import '../services/google_sheet_service.dart';
import '../services/spin_history_service.dart';
import '../theme/app_gradients.dart';
import '../widgets/gradient_widgets.dart';
import 'food_detail_screen.dart';

/// Danh sách các lần quay trúng món (mới nhất trên cùng).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SpinHistoryService _historyService = SpinHistoryService();
  final GoogleSheetService _sheetService = GoogleSheetService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _spins = <Map<String, dynamic>>[];
  SheetData? _sheetData;

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final SheetData data = await _sheetService.fetchAllTables();
      final List<Map<String, dynamic>> spins = await _historyService.spinsNewestFirst();
      if (!mounted) {
        return;
      }
      setState(() {
        _sheetData = data;
        _spins = spins;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sheetData = null;
        _spins = <Map<String, dynamic>>[];
        _loading = false;
        _error = 'Không tải được dữ liệu.';
      });
    }
  }

  Food? _foodFromSheet(String foodId) {
    final List<Food> foods = _sheetData?.foods ?? <Food>[];
    for (final Food f in foods) {
      if (f.id == foodId) {
        return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppGradients.primaryMid),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_spins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GradientText(
            'Chưa có lần quay nào.\nVào tab Vòng quay và quay để lưu lịch sử.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppGradients.primaryMid,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _spins.length,
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> row = _spins[index];
          final String foodId = (row['foodId'] as String? ?? '').trim();
          final String storedName = (row['foodName'] as String? ?? '').trim();
          final Food? food = foodId.isEmpty ? null : _foodFromSheet(foodId);
          final String title = food?.name ?? storedName;
          DateTime? at;
          try {
            final String? raw = row['at'] as String?;
            if (raw != null && raw.isNotEmpty) {
              at = DateTime.tryParse(raw)?.toLocal();
            }
          } catch (_) {}

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            leading: _HistoryLeading(
              imageUrl: food?.imageUrl,
              name: title,
            ),
            title: Text(
              title.isEmpty ? '(Không tên)' : title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: at != null
                ? Text(
                    _dateFormat.format(at),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8A8A8E),
                        ),
                  )
                : null,
            trailing: food != null
                ? Icon(Icons.chevron_right_rounded, color: AppGradients.primaryMid)
                : null,
            onTap: food != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => FoodDetailScreen(food: food),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _HistoryLeading extends StatelessWidget {
  const _HistoryLeading({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? st) =>
            _Placeholder(name: name),
        ),
      );
    }
    return _Placeholder(name: name);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String initial = name.isEmpty
        ? '?'
        : name.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppGradients.primaryStart.withValues(alpha: 0.35),
      child: Text(
        initial,
        style: TextStyle(
          color: AppGradients.primaryMid,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    );
  }
}
