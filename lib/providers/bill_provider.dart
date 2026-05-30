import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/bill_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';

class BillProvider with ChangeNotifier {
  final BillService _billService = BillService();

  List<BillData> _bills = [];
  bool _isLoading = false;
  String? _error;

  List<BillData> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BillData? lastBill(String tipo) {
    final byType = _bills.where((b) => b.tipo == tipo).toList();
    return byType.isNotEmpty ? byType.first : null;
  }

  BillData? previousBill(String tipo) {
    final byType = _bills.where((b) => b.tipo == tipo).toList();
    return byType.length > 1 ? byType[1] : null;
  }

  double? consumoChangePercent(String tipo) {
    final last = lastBill(tipo);
    final prev = previousBill(tipo);
    if (last == null || prev == null) return null;

    final lastVal = _parseConsumo(last.consumo);
    final prevVal = _parseConsumo(prev.consumo);
    if (prevVal <= 0) return null;

    return ((lastVal - prevVal) / prevVal) * 100;
  }

  int xpForBill(String tipo) {
    return 25;
  }

  bool exceedsMeta(String tipo, int metaPercent) {
    final change = consumoChangePercent(tipo);
    if (change == null) return false;

    return change > -(metaPercent.toDouble());
  }

  String savingsAmount(String tipo) {
    final last = lastBill(tipo);
    final prev = previousBill(tipo);
    if (last == null || prev == null) return '\$0';

    final lastMonto = _parseMonto(last.monto);
    final prevMonto = _parseMonto(prev.monto);
    final diff = prevMonto - lastMonto;
    if (diff <= 0) return '\$0';

    return '\$${diff.toStringAsFixed(0)}';
  }

  String totalSavings() {
    double total = 0;
    for (final tipo in ['luz', 'agua']) {
      final last = lastBill(tipo);
      final prev = previousBill(tipo);
      if (last != null && prev != null) {
        final diff = _parseMonto(prev.monto) - _parseMonto(last.monto);
        if (diff > 0) total += diff;
      }
    }
    if (total == 0) return '\$0';
    return '\$${total.toStringAsFixed(0)}';
  }

  double familyEnergyPercent(int metaLuz, int metaAgua) {
    double score = 0;
    int count = 0;

    for (final entry in [
      {'tipo': 'luz', 'meta': metaLuz},
      {'tipo': 'agua', 'meta': metaAgua},
    ]) {
      final tipo = entry['tipo'] as String;
      final meta = entry['meta'] as int;
      final change = consumoChangePercent(tipo);
      if (change != null) {
        final achieved = (-change / meta).clamp(0.0, 1.0);
        score += achieved;
        count++;
      }
    }

    if (count == 0) return 0.5;
    return score / count;
  }

  double _parseConsumo(String raw) {
    final match = RegExp(r'[\d,.]+').firstMatch(raw.replaceAll(',', ''));
    return match != null ? double.tryParse(match.group(0)!) ?? 0 : 0;
  }

  double _parseMonto(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> loadBills(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _billService.getBills(familyId);
    } catch (e) {
      _error = e.toString();

      _bills = _mockBills();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_bills') ?? [];
      _bills.removeWhere((b) => deletedIds.contains(b.id));

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBill(
    BillData bill, {
    AchievementProvider? achievementProvider,
    AuthProvider? authProvider,
  }) async {
    try {
      await _billService.createBill(bill);
      if (bill.familyId != null) {
        await loadBills(bill.familyId!);
      } else {
        _bills.insert(0, bill);
        notifyListeners();
      }

      if (achievementProvider != null && authProvider != null) {
        final userId = authProvider.profile?.id;
        if (userId != null) {
          achievementProvider
              .checkAndUnlock(
                userId,
                'primer_recibo',
                authProvider: authProvider,
              )
              .ignore();

          final luzCount = _bills.where((b) => b.tipo == 'luz').length;
          final aguaCount = _bills.where((b) => b.tipo == 'agua').length;

          if (luzCount >= 3) {
            achievementProvider
                .checkAndUnlock(
                  userId,
                  'ahorro_luz',
                  authProvider: authProvider,
                )
                .ignore();
          }
          if (aguaCount >= 3) {
            achievementProvider
                .checkAndUnlock(
                  userId,
                  'ahorro_agua',
                  authProvider: authProvider,
                )
                .ignore();
          }
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBill(String id) async {
    try {
      await _billService.deleteBill(id);
      _bills.removeWhere((b) => b.id == id);

      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList('deleted_bills') ?? [];
      deleted.add(id);
      await prefs.setStringList('deleted_bills', deleted);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();

      _bills.removeWhere((b) => b.id == id);

      final prefs = await SharedPreferences.getInstance();
      final deleted = prefs.getStringList('deleted_bills') ?? [];
      deleted.add(id);
      await prefs.setStringList('deleted_bills', deleted);

      notifyListeners();
      return false;
    }
  }

  List<BillData> _mockBills() {
    return [
      BillData(
        id: 'm1',
        tipo: 'luz',
        consumo: '310 kWh',
        monto: '\$1,020.00',
        periodo: 'Mar-Abr 2025',
        empresa: 'CFE',
        cuenta: '52103-00421',
        tarifa: 'DAC',
      ),
      BillData(
        id: 'm2',
        tipo: 'luz',
        consumo: '380 kWh',
        monto: '\$1,240.50',
        periodo: 'Feb-Mar 2025',
        empresa: 'CFE',
        cuenta: '52103-00421',
        tarifa: 'DAC',
      ),
      BillData(
        id: 'm3',
        tipo: 'agua',
        consumo: '18 m³',
        monto: '\$480.00',
        periodo: 'Mar-Abr 2025',
        empresa: 'SAPAM',
        cuenta: '83-004-21',
        tarifa: 'Dom',
      ),
      BillData(
        id: 'm4',
        tipo: 'agua',
        consumo: '22 m³',
        monto: '\$580.00',
        periodo: 'Feb-Mar 2025',
        empresa: 'SAPAM',
        cuenta: '83-004-21',
        tarifa: 'Dom',
      ),
    ];
  }

  void clear() {
    _bills = [];
    notifyListeners();
  }
}
