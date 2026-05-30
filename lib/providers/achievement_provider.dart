import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/achievement_service.dart';
import '../services/task_service.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../config/constants.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  final TaskService _taskService = TaskService();

  final List<AchievementItem> _catalog = [
    AchievementItem(
      key: 'primer_registro',
      nombre: '¡Hola Mundo Verde!',
      desc: 'Sube tu primera evidencia al feed.',
      emoji: '🌿',
      dificultad: AppConstants.dificilFacil,
      xp: 100,
      monedas: 10,
    ),
    AchievementItem(
      key: 'primer_recibo',
      nombre: 'Cuentas Claras',
      desc: 'Registra tu primer recibo de servicio.',
      emoji: '📝',
      dificultad: AppConstants.dificilFacil,
      xp: 120,
      monedas: 15,
    ),
    AchievementItem(
      key: 'unirse_familia',
      nombre: 'Miembro Oficial',
      desc: 'Únete a un grupo familiar o crea uno nuevo.',
      emoji: '🏠',
      dificultad: AppConstants.dificilFacil,
      xp: 150,
      monedas: 20,
    ),
    AchievementItem(
      key: 'primer_reto',
      nombre: 'Retador Inicial',
      desc: 'Completa o sube tu primer eco-reto.',
      emoji: '🚿',
      dificultad: AppConstants.dificilFacil,
      xp: 100,
      monedas: 10,
    ),
    AchievementItem(
      key: 'primer_canje',
      nombre: 'El Esfuerzo Vale',
      desc: 'Canjea tu primera recompensa de la tienda.',
      emoji: '🎁',
      dificultad: AppConstants.dificilFacil,
      xp: 120,
      monedas: 15,
    ),
    AchievementItem(
      key: 'eco_trivia',
      nombre: 'Cerebro Verde',
      desc: 'Trivia perfecta (150 XP) en la Trivia Infinita.',
      emoji: '🧠',
      dificultad: AppConstants.dificilMedio,
      xp: 300,
      monedas: 50,
    ),
    AchievementItem(
      key: 'eco_puzzle',
      nombre: 'Maestro del Reciclaje',
      desc: 'Puntuación perfecta (30/30) en el Eco-Puzzle.',
      emoji: '🎯',
      dificultad: AppConstants.dificilMedio,
      xp: 300,
      monedas: 50,
    ),
    AchievementItem(
      key: 'racha_constancia',
      nombre: 'Eco Constancia',
      desc: 'Reclama el Bonus de Constancia Diaria.',
      emoji: '⚡',
      dificultad: AppConstants.dificilMedio,
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'ahorro_agua',
      nombre: 'Ahorro Fluyente',
      desc: 'Registra 3 recibos de agua.',
      emoji: '💧',
      dificultad: AppConstants.dificilMedio,
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'ahorro_luz',
      nombre: 'Energía Limpia',
      desc: 'Registra 3 recibos de luz.',
      emoji: '💡',
      dificultad: AppConstants.dificilMedio,
      xp: 250,
      monedas: 40,
    ),
    AchievementItem(
      key: 'multiples_evidencias',
      nombre: 'Cronista Verde',
      desc: 'Sube un total de 10 evidencias ecológicas.',
      emoji: '📸',
      dificultad: AppConstants.dificilDificil,
      xp: 500,
      monedas: 100,
    ),
    AchievementItem(
      key: 'nivel_cinco',
      nombre: 'Eco Héroe',
      desc: 'Alcanza el nivel 5 de conciencia ecológica.',
      emoji: '🎖️',
      dificultad: AppConstants.dificilDificil,
      xp: 400,
      monedas: 80,
    ),
    AchievementItem(
      key: 'nivel_diez',
      nombre: 'Eco Leyenda',
      desc: 'Alcanza el nivel 10 de conciencia ecológica.',
      emoji: '👑',
      dificultad: AppConstants.dificilDificil,
      xp: 1000,
      monedas: 200,
    ),
    AchievementItem(
      key: 'monedas_cien',
      nombre: 'Rico en Ecología',
      desc: 'Acumula un balance de 100 monedas.',
      emoji: '💰',
      dificultad: AppConstants.dificilDificil,
      xp: 500,
      monedas: 100,
    ),
    AchievementItem(
      key: 'jefe_aprobador',
      nombre: 'Eco Juez',
      desc: 'Como Jefe de Familia, aprueba un reto o canje.',
      emoji: '⚖️',
      dificultad: AppConstants.dificilDificil,
      xp: 400,
      monedas: 80,
    ),
    AchievementItem(
      key: 'trivia_25',
      nombre: 'Sabio Verde',
      desc: 'Responde 25 preguntas correctas seguidas en Trivia.',
      emoji: '🧙‍♂️',
      dificultad: AppConstants.dificilMedio,
      xp: 250,
      monedas: 30,
    ),
    AchievementItem(
      key: 'trivia_50',
      nombre: 'Erudito de la Tierra',
      desc: 'Responde 50 preguntas correctas seguidas en Trivia.',
      emoji: '🌍',
      dificultad: AppConstants.dificilMedio,
      xp: 500,
      monedas: 60,
    ),
    AchievementItem(
      key: 'trivia_75',
      nombre: 'Guardián del Ecosistema',
      desc: 'Responde 75 preguntas correctas seguidas en Trivia.',
      emoji: '🛡️',
      dificultad: AppConstants.dificilDificil,
      xp: 750,
      monedas: 100,
    ),
    AchievementItem(
      key: 'trivia_100',
      nombre: 'Deidad de la Ecología',
      desc: 'Responde 100 preguntas correctas seguidas en Trivia.',
      emoji: '🔱',
      dificultad: AppConstants.dificilDificil,
      xp: 1500,
      monedas: 200,
    ),
  ];

  final Map<String, String> _unlockedKeysWithDate = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<AchievementItem> get achievements {
    return _catalog.map((c) {
      final isUnlocked = _unlockedKeysWithDate.containsKey(c.key);
      final unlockedAtStr = _unlockedKeysWithDate[c.key];
      return c.copyWith(
        desbloqueado: isUnlocked,
        desbloqueadoEn: unlockedAtStr,
      );
    }).toList();
  }

  Future<void> loadForUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final unlocked = await _achievementService.getUnlockedAchievements(
        userId,
      );
      _unlockedKeysWithDate.clear();
      for (final row in unlocked) {
        final key = row['logro_key'] as String;
        final dateStr = row['desbloqueado_en'] as String? ?? '';
        _unlockedKeysWithDate[key] = dateStr;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading achievements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAndUnlock(
    String userId,
    String logroKey, {
    required AuthProvider authProvider,
  }) async {
    if (_unlockedKeysWithDate.containsKey(logroKey)) return;

    try {
      final currentUnlocked = await _achievementService.getUnlockedAchievements(
        userId,
      );
      final keys = currentUnlocked.map((r) => r['logro_key'] as String).toSet();

      _unlockedKeysWithDate.clear();
      for (final row in currentUnlocked) {
        final k = row['logro_key'] as String;
        final d = row['desbloqueado_en'] as String? ?? '';
        _unlockedKeysWithDate[k] = d;
      }

      if (keys.contains(logroKey)) {
        notifyListeners();
        return;
      }

      final item = _catalog.firstWhere((c) => c.key == logroKey);

      await _achievementService.unlockAchievement(userId, logroKey);

      final leveledUp = await _taskService.rewardUser(
        userId,
        item.xp,
        item.monedas,
      );

      final timeNow = DateTime.now().toIso8601String();
      await NotificationProvider.writeNotificationForUser(
        userId,
        NotificationItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_logro_$logroKey',
          title: '🏆 Logro Desbloqueado: ${item.nombre}',
          desc:
              '¡Genial! Desbloqueaste "${item.nombre}" y ganaste +${item.xp} XP y +${item.monedas} 🪙!',
          time: timeNow,
          iconCode: 'emoji_events',
          colorHex: '#F9A825',
        ),
      );

      if (leveledUp) {
        await NotificationProvider.writeNotificationForUser(
          userId,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_nivel',
            title: '¡Subiste de nivel!',
            desc:
                '¡Felicidades! Has alcanzado un nuevo nivel por desbloquear el logro ${item.nombre}.',
            time: timeNow,
            iconCode: 'star',
            colorHex: '#1976D2',
          ),
        );
      }

      await authProvider.refreshProfile();

      _unlockedKeysWithDate[logroKey] = timeNow;
      notifyListeners();

      debugPrint('✓ Achievement unlocked successfully: $logroKey');
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  void checkProfileAchievements(
    UserProfile profile,
    AuthProvider authProvider,
  ) {
    final userId = profile.id;
    if (profile.familyId != null && profile.familyId!.isNotEmpty) {
      checkAndUnlock(
        userId,
        'unirse_familia',
        authProvider: authProvider,
      ).ignore();
    }
    if (profile.nivel >= 5) {
      checkAndUnlock(
        userId,
        'nivel_cinco',
        authProvider: authProvider,
      ).ignore();
    }
    if (profile.nivel >= 10) {
      checkAndUnlock(userId, 'nivel_diez', authProvider: authProvider).ignore();
    }
    if (profile.monedas >= 100) {
      checkAndUnlock(
        userId,
        'monedas_cien',
        authProvider: authProvider,
      ).ignore();
    }
  }

  void clear() {
    _unlockedKeysWithDate.clear();
    notifyListeners();
  }
}
