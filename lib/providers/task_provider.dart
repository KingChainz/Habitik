import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/task_service.dart';
import '../services/validation_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final ValidationService _validationService = ValidationService();

  final List<PendingValidation> _pendingValidations = [];
  Set<String> _completedRetos = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  String? _currentFamilyId;

  TaskProvider();

  List<PendingValidation> get pendingValidations => _pendingValidations;
  Set<String> get completedRetos => _completedRetos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForUser(String userId, {String? familyId}) async {
    _currentUserId = userId;
    _currentFamilyId = familyId;
    _completedRetos = {};
    await _loadLocalRetos(userId);
    if (familyId != null) {
      await _loadPendingValidations(familyId);
    }
  }

  Future<void> _loadLocalRetos(String? userId) async {
    if (userId == null) return;
    try {
      final response = await _validationService.getRetosForUserToday(userId);

      final completedTitles = response
          .map((e) => e['reto'] as String)
          .toList();

      final Set<String> todayCompleted = {};
      for (final title in completedTitles) {
        final t = title.toLowerCase();
        if (t.contains('ducha')) {
          todayCompleted.add('ducha');
        } else if (t.contains('inspección') || t.contains('inspeccion')) {
          todayCompleted.add('inspeccion');
        } else if (t.contains('trivia')) {
          todayCompleted.add('trivia');
        } else if (t.contains('puzzle')) {
          todayCompleted.add('puzzle');
        } else if (t.contains('wordle')) {
          todayCompleted.add('wordle');
        }
      }

      _completedRetos = todayCompleted;
      notifyListeners();
    } catch (e) {
      debugPrint('TaskProvider: error loading completed retos: $e');
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final savedDate = prefs.getString('completed_retos_date_$userId');
      if (savedDate == today) {
        final savedList =
            prefs.getStringList('completed_retos_list_$userId') ?? [];
        _completedRetos = savedList.toSet();
        notifyListeners();
      } else {
        await prefs.remove('completed_retos_list_$userId');
        await prefs.setString('completed_retos_date_$userId', today);
      }
    }
  }

  void markRetoCompleted(String retoId) async {
    _completedRetos.add(retoId);
    notifyListeners();
    if (_currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('completed_retos_date_$_currentUserId', today);
    await prefs.setStringList(
      'completed_retos_list_$_currentUserId',
      _completedRetos.toList(),
    );
  }

  Future<void> _loadPendingValidations(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final remote = await _validationService.getPendingForFamily(familyId);
      _pendingValidations.clear();
      _pendingValidations.addAll(remote);
      debugPrint(
        'TaskProvider: loaded ${_pendingValidations.length} validations from Supabase',
      );
      notifyListeners();

      await _savePendingValidations();
    } catch (e) {
      debugPrint(
        'TaskProvider: Supabase load failed ($e) — falling back to SP',
      );
      await _loadPendingValidationsFromSP(familyId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPendingValidationsFromSP(String familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_validations_$familyId');
      debugPrint(
        'TaskProvider: loading pending_validations_$familyId → raw=${raw?.length} chars',
      );
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _pendingValidations.clear();
        _pendingValidations.addAll(
          list.map(
            (e) => PendingValidation.fromJson(e as Map<String, dynamic>),
          ),
        );
        debugPrint(
          'TaskProvider: loaded ${_pendingValidations.length} pending validations from SP',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TaskProvider: ERROR loading pending validations from SP: $e');
    }
  }

  Future<void> _savePendingValidations() async {
    if (_currentFamilyId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        _pendingValidations.map((v) => v.toJson()).toList(),
      );
      await prefs.setString('pending_validations_$_currentFamilyId', encoded);
      debugPrint(
        'TaskProvider: saved ${_pendingValidations.length} pending validations for family $_currentFamilyId',
      );
    } catch (e) {
      debugPrint('TaskProvider: ERROR saving pending validations: $e');
    }
  }

  Future<void> addValidation(
    PendingValidation pv, {
    String? familyId,
    AchievementProvider? achievementProvider,
    AuthProvider? authProvider,
  }) async {
    if (familyId != null) _currentFamilyId = familyId;
    debugPrint(
      'TaskProvider: addValidation → familyId=$_currentFamilyId, reto=${pv.reto}',
    );

    bool supabaseOk = false;
    if (_currentFamilyId != null) {
      try {
        await _validationService.insertValidation(pv, _currentFamilyId!);
        supabaseOk = true;
        debugPrint('TaskProvider: ✓ inserted validation to Supabase');
      } catch (e) {
        debugPrint('TaskProvider: Supabase insert failed ($e) — using SP only');
      }
    }

    _pendingValidations.insert(0, pv);
    notifyListeners();

    if (!supabaseOk) {
      await _savePendingValidations();
    }

    if (achievementProvider != null && authProvider != null) {
      achievementProvider
          .checkAndUnlock(pv.userId, 'primer_reto', authProvider: authProvider)
          .ignore();
    }
  }

  Future<void> refreshValidations() async {
    if (_currentFamilyId == null) return;
    await _loadPendingValidations(_currentFamilyId!);
  }

  Future<bool> approveValidation(int validationId) async {
    final index = _pendingValidations.indexWhere((v) => v.id == validationId);
    if (index == -1) return false;

    final validation = _pendingValidations[index];
    _pendingValidations.removeAt(index);

    bool leveledUp = false;
    final isCanje =
        validation.evidencias.isEmpty || validation.evidencias.first == 'Canje';
    if (!isCanje && validation.requiereEvidencia) {
      try {
        leveledUp = await _taskService.rewardUser(
          validation.userId,
          validation.xp,
          validation.monedas,
        );
      } catch (e) {
        debugPrint('Error rewarding user: $e');
      }
    }

    try {
      await _validationService.markApproved(validationId);
    } catch (e) {
      debugPrint('TaskProvider: Supabase approve failed: $e');
    }

    notifyListeners();
    await _savePendingValidations();
    return leveledUp;
  }

  Future<void> rejectValidation(int validationId, String motivo) async {
    final index = _pendingValidations.indexWhere((v) => v.id == validationId);
    if (index == -1) return;

    final validation = _pendingValidations[index];
    _pendingValidations.removeAt(index);

    final isCanje =
        validation.evidencias.isEmpty || validation.evidencias.first == 'Canje';
    if (isCanje) {
      try {
        await _taskService.rewardUser(validation.userId, 0, validation.monedas);
      } catch (e) {
        debugPrint('Error refunding user: $e');
      }
    }

    try {
      await _validationService.markRejected(validationId);
    } catch (e) {
      debugPrint('TaskProvider: Supabase reject failed: $e');
    }

    notifyListeners();
    await _savePendingValidations();
  }

  Future<bool> rewardUser(String userId, int xp, int monedas) async {
    try {
      return await _taskService.rewardUser(userId, xp, monedas);
    } catch (e) {
      debugPrint('Error rewarding user direct: $e');
      return false;
    }
  }

  void clear() {
    _pendingValidations.clear();
    _completedRetos.clear();
    notifyListeners();
  }
}
