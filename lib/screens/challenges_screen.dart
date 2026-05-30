import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/evidence_provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/family_provider.dart';
import '../config/constants.dart';
import '../services/api_client.dart';
import 'games/ducha_challenge.dart';
import 'games/trivia_challenge.dart';
import 'games/puzzle_challenge.dart';
import 'games/evidence_challenge.dart';
import 'games/wordle_challenge.dart';

class ChallengesScreen extends StatefulWidget {
  final String active;
  final VoidCallback onBack;
  final void Function(String) onSelect;

  const ChallengesScreen({
    super.key,
    required this.active,
    required this.onBack,
    required this.onSelect,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool _dailyBonusClaimed = false;
  int _triviaCorrectCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBonusState();
  }

  Future<void> _loadBonusState() async {
    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    bool claimed = false;
    if (auth != null && auth.profile != null) {
      claimed = auth.profile!.dailyBonusClaimedAt == today;
    }
    if (!claimed) {
      final claimedDate = prefs.getString('daily_bonus_claimed_date');
      claimed = claimedDate == today;
    }
    int triviaScore = 0;
    if (auth != null && auth.profile != null) {
      if (auth.profile!.triviaLastUpdated == today) {
        triviaScore = auth.profile!.triviaCorrectCount;
      }
    }
    if (triviaScore == 0) {
      triviaScore = prefs.getInt('last_trivia_correct_count_$today') ?? 0;
    }
    setState(() {
      _dailyBonusClaimed = claimed;
      _triviaCorrectCount = triviaScore;
    });
  }

  Future<void> _claimDailyBonus() async {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    setState(() => _dailyBonusClaimed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('daily_bonus_claimed_date', today);
    } catch (_) {}
    try {
      await auth.updateDailyBonusClaimedAt(today);
      await taskProvider.rewardUser(userId, 30, 5);
    } catch (e) {
      debugPrint('Error al reclamar bono diario: $e');
    }
    if (!mounted) return;
    await auth.refreshProfile();
    if (!mounted) return;
    final familyId = auth.profile?.familyId;
    if (familyId != null) {
      context.read<EvidenceProvider>().addEvidence(
        Evidence(
          userId: userId,
          familyId: familyId,
          autor: auth.profile!.nombre,
          avatar: auth.profile!.nombre[0],
          color: auth.profile!.avatarColor,
          avatarUrl: auth.profile?.avatarUrl,
          accion: '⚡ Bonus de constancia diaria desbloqueado',
          desc: 'Completó 2 retos diferentes hoy y ganó +30 XP · +5 🪙',
          likes: 0,
          tiempo: DateTime.now().toIso8601String(),
          xp: 30,
          emoji: '⚡',
        ),
        achievementProvider: context.read<AchievementProvider>(),
        authProvider: context.read<AuthProvider>(),
      );
    }
    context
        .read<AchievementProvider>()
        .checkAndUnlock(
          userId,
          'racha_constancia',
          authProvider: context.read<AuthProvider>(),
        )
        .ignore();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.bolt, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '¡Bonus de Constancia desbloqueado! +30 XP · +5 🪙',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: Color(0xFF7B1FA2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  final List<ChallengeType> _retos = [
    ChallengeType(
      id: 'ducha',
      emoji: '🚿',
      titulo: 'Speedrun de la Ducha',
      desc: 'Dúchate en menos de 10 min',
      xp: 50,
      monedas: 5,
      color: '#1565c0',
    ),
    ChallengeType(
      id: 'inspeccion',
      emoji: '🔍',
      titulo: 'Inspección del Día',
      desc: 'Misión rotativa para el hogar',
      xp: 100,
      monedas: 15,
      color: '#f57c00',
    ),
    ChallengeType(
      id: 'trivia',
      emoji: '🧠',
      titulo: 'Trivia Infinita',
      desc: '3 vidas · preguntas de ecología',
      xp: 150,
      monedas: 15,
      color: AppConstants.colorPurple,
    ),
    ChallengeType(
      id: 'puzzle',
      emoji: '🎯',
      titulo: 'Eco-Puzzle Temático',
      desc: 'Clasifica residuos en 60s',
      xp: 120,
      monedas: 20,
      color: '#c62828',
    ),
    ChallengeType(
      id: 'wordle',
      emoji: '🔤',
      titulo: 'Eco-Wordle del Día',
      desc: 'Adivina la palabra ecológica de hoy',
      xp: 50,
      monedas: 5,
      color: AppConstants.colorGreen,
    ),
  ];

  Color _parseColor(String hex) =>
      Color(int.parse(hex.replaceAll('#', '0xFF')));

  Future<void> _submitChallenge(
    String id,
    String title,
    int xp,
    int monedas,
    List<String> evidencias,
    bool requiereEvidencia,
    String color,
  ) async {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final achievementProvider = context.read<AchievementProvider>();
    final familyMembers = context.read<FamilyProvider>().members;
    if (auth.profile == null) return;
    List<String> finalEvidencias = [];
    if (evidencias.isNotEmpty && evidencias.first != 'Canje') {
      for (final path in evidencias) {
        if (path.contains('/') || path.contains('\\')) {
          try {
            final url = await ApiClient().uploadFile('/upload', path);
            finalEvidencias.add(url);
          } catch (e) {
            debugPrint('Error uploading evidence image: $e');
          }
        } else {
          finalEvidencias.add(path);
        }
      }
    } else {
      finalEvidencias = List.from(evidencias);
    }
    if (!requiereEvidencia) {
      final leveledUp = await taskProvider.rewardUser(
        auth.profile!.id,
        xp,
        monedas,
      );
      if (leveledUp && mounted) {
        NotificationProvider.writeNotificationForUser(
          auth.profile!.id,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_nivel',
            title: '¡Subiste de nivel!',
            desc:
                '¡Felicidades! Has alcanzado un nuevo nivel por completar $title.',
            time: DateTime.now().toIso8601String(),
            iconCode: 'emoji_events',
            colorHex: '#F9A825',
          ),
        );
      }
      if (!mounted) return;
      await auth.refreshProfile();
      if (!mounted) return;
    } else {
      final jefes = familyMembers
          .where((m) => m.rol.toLowerCase().contains('jefe'))
          .toList();
      for (var jefe in jefes) {
        NotificationProvider.writeNotificationForUser(
          jefe.id,
          NotificationItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_val',
            title: 'Validación pendiente',
            desc: '${auth.profile!.nombre.split(' ')[0]} completó "$title".',
            time: DateTime.now().toIso8601String(),
            iconCode: 'check_circle',
            colorHex: '#1976D2',
          ),
        );
      }
    }
    await taskProvider.addValidation(
      PendingValidation(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: auth.profile!.id,
        usuario: auth.profile!.nombre,
        avatar: auth.profile!.nombre[0],
        color: color,
        reto: title,
        hora: 'Recién',
        xp: xp,
        monedas: monedas,
        evidencias: finalEvidencias,
        requiereEvidencia: requiereEvidencia,
      ),
      familyId: auth.profile!.familyId,
      achievementProvider: achievementProvider,
      authProvider: auth,
    );
    if (!mounted) return;
    taskProvider.markRetoCompleted(id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.active == 'ducha') {
      return DuchaChallenge(
        onBack: widget.onBack,
        onSubmit: (xp, monedas, evidencias) => _submitChallenge(
          'ducha',
          'Speedrun de la Ducha',
          xp,
          monedas,
          evidencias,
          false,
          '#1565c0',
        ),
      );
    }
    if (widget.active == 'trivia') {
      return TriviaChallenge(
        onBack: widget.onBack,
        initialTriviaCorrectCount: _triviaCorrectCount,
        onCorrectAnswer: (correctCount) {
          setState(() {
            _triviaCorrectCount = correctCount;
          });
        },
        onSubmit: (score, correctCount, perfect) {
          setState(() {
            _triviaCorrectCount = correctCount;
          });
          return _submitChallenge(
            'trivia',
            perfect ? 'Trivia Infinita - 100/100' : 'Trivia Infinita',
            score,
            (score * 0.1).round(),
            perfect
                ? ['Completó las 100 preguntas perfectas. Puntaje: $score XP']
                : [
                    'Puntaje: $score XP',
                    'Respuestas correctas: $correctCount',
                  ],
            false,
            AppConstants.colorPurple,
          );
        },
      );
    }
    if (widget.active == 'puzzle') {
      return PuzzleChallenge(
        onBack: widget.onBack,
        onSubmit: (pzTitle, xp, monedas) => _submitChallenge(
          'puzzle',
          pzTitle,
          xp,
          monedas,
          [],
          false,
          '#c62828',
        ),
      );
    }
    if (widget.active == 'inspeccion') {
      return EvidenceChallenge(
        active: widget.active,
        onBack: widget.onBack,
        onSubmit: (titulo, xp, monedas, evidencias) => _submitChallenge(
          widget.active,
          titulo,
          xp,
          monedas,
          evidencias,
          true,
          '#f57c00',
        ),
      );
    }
    if (widget.active == 'wordle') {
      return WordleChallenge(
        onBack: widget.onBack,
        onSubmit: (xp, monedas, evidencias) => _submitChallenge(
          'wordle',
          'Eco-Wordle del Día',
          xp,
          monedas,
          evidencias,
          false,
          AppConstants.colorGreen,
        ),
      );
    }
    return _buildChallengeList();
  }

  Widget _buildChallengeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gamificación',
                style: TextStyle(color: AppTheme.green200, fontSize: 12),
              ),
              Text(
                'Retos del Día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.amber400.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.amber400.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              'Racha semanal',
                              style: TextStyle(
                                color: AppTheme.amber400,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final auth = context.watch<AuthProvider>();
                            final evidenceProv = context
                                .watch<EvidenceProvider>();
                            final taskProv = context.watch<TaskProvider>();
                            final now = DateTime.now();
                            final currentWeekday = now.weekday;
                            final monday = now.subtract(
                              Duration(days: currentWeekday - 1),
                            );
                            final weekDays = [
                              'Lun',
                              'Mar',
                              'Mié',
                              'Jue',
                              'Vie',
                              'Sáb',
                              'Dom',
                            ];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(7, (index) {
                                final dayDate = monday.add(
                                  Duration(days: index),
                                );
                                final isToday =
                                    dayDate.day == now.day &&
                                    dayDate.month == now.month &&
                                    dayDate.year == now.year;
                                final isPast = dayDate.isBefore(
                                  DateTime(now.year, now.month, now.day),
                                );
                                final done = _hasCompletedRetoOnDay(
                                  dayDate,
                                  auth.user?.id,
                                  evidenceProv.evidences,
                                  taskProv.pendingValidations,
                                  taskProv.completedRetos,
                                );
                                final missed = isPast && !done;
                                return Column(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: done
                                            ? AppTheme.green500
                                            : (missed
                                                ? Colors.red.shade100
                                                : (isToday
                                                    ? AppTheme.amber400
                                                        .withValues(
                                                          alpha: 0.2,
                                                        )
                                                    : Colors
                                                        .grey
                                                        .shade100)),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: done
                                              ? AppTheme.green600
                                              : (missed
                                                  ? Colors.red.shade300
                                                  : (isToday
                                                      ? AppTheme.amber400
                                                      : Colors
                                                          .grey
                                                          .shade200)),
                                        ),
                                      ),
                                      child: done
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : (missed
                                              ? const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: 16,
                                                )
                                              : (isToday
                                                  ? const Icon(
                                                      Icons.circle,
                                                      color:
                                                          AppTheme.amber400,
                                                      size: 8,
                                                    )
                                                  : null)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dayDate.day}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isToday
                                            ? FontWeight.w900
                                            : FontWeight.normal,
                                        color: done
                                            ? AppTheme.green700
                                            : (missed
                                                ? Colors.red.shade700
                                                : (isToday
                                                    ? AppTheme.amber400
                                                    : Colors
                                                        .grey
                                                        .shade600)),
                                      ),
                                    ),
                                    Text(
                                      weekDays[index],
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: done
                                            ? AppTheme.green700
                                            : (missed
                                                ? Colors.red.shade400
                                                : Colors.grey.shade400),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final completed = context
                          .watch<TaskProvider>()
                          .completedRetos
                          .length;
                      final canClaim = completed >= 2 && !_dailyBonusClaimed;
                      final progress = completed.clamp(0, 2);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _dailyBonusClaimed
                                ? [
                                    const Color(0xFFE8F5E9),
                                    const Color(0xFFC8E6C9),
                                  ]
                                : [
                                    const Color(0xFFF3E5F5),
                                    const Color(0xFFE1BEE7),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _dailyBonusClaimed
                                ? AppTheme.green400
                                : const Color(
                                    0xFF7B1FA2,
                                  ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                const Text(
                                  'Bonus de Constancia Diaria',
                                  style: TextStyle(
                                    color: Color(0xFF7B1FA2),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7B1FA2,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+30 XP',
                                        style: TextStyle(
                                          color: Color(0xFF7B1FA2),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        ' · ',
                                        style: TextStyle(
                                          color: Color(0xFF7B1FA2),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        '+5 🪙',
                                        style: TextStyle(
                                          color: Color(0xFF7B1FA2),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _dailyBonusClaimed
                                  ? '✅ Bonus reclamado hoy. ¡Vuelve mañana!'
                                  : 'Completa 2 retos hoy para desbloquear el bonus',
                              style: TextStyle(
                                color: _dailyBonusClaimed
                                    ? AppTheme.green700
                                    : const Color(0xFF6A1B9A),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress / 2,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                                valueColor: AlwaysStoppedAnimation(
                                  _dailyBonusClaimed
                                      ? AppTheme.green500
                                      : const Color(0xFF7B1FA2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$progress / 2 retos completados',
                                  style: const TextStyle(
                                    color: Color(0xFF7B1FA2),
                                    fontSize: 11,
                                  ),
                                ),
                                if (canClaim)
                                  GestureDetector(
                                    onTap: _claimDailyBonus,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B1FA2),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7B1FA2)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Reclamar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _retos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = _retos[index];
                      final color = _parseColor(r.color);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              widget.onSelect(r.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            r.emoji,
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (context
                                          .watch<TaskProvider>()
                                          .completedRetos
                                          .contains(r.id))
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: AppTheme.green600,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.titulo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textDark,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            if (r.id == 'trivia')
                                              GestureDetector(
                                                onTap: () {
                                                  _showTriviaRankingBottomSheet(
                                                    context,
                                                  );
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.amber400
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.emoji_events,
                                                    color: AppTheme.amber500,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.desc,
                                          style: const TextStyle(
                                            color: AppTheme.textLight,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '+${r.xp} XP',
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '+${r.monedas} 🪙',
                                              style: const TextStyle(
                                                color: AppTheme.amber500,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textLight,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTriviaRankingBottomSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final familyId = auth.profile?.familyId;
    if (familyId != null) {
      context.read<FamilyProvider>().loadFamilyMembers(familyId);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final currentUserId = sheetContext.read<AuthProvider>().profile?.id;
        final familyProv = sheetContext.watch<FamilyProvider>();
        final members = List<FamilyMember>.from(familyProv.members);
        final Map<String, int> scores = {};
        final today = DateTime.now().toIso8601String().split('T')[0];
        for (var m in members) {
          if (m.id == currentUserId) {
            scores[m.id] = _triviaCorrectCount;
          } else {
            scores[m.id] = m.triviaLastUpdated == today
                ? m.triviaCorrectCount
                : 0;
          }
        }
        members.sort(
          (a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0),
        );
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.purple700.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppTheme.purple700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranking del Hogar',
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Trivia Infinita del Día 🧠',
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Aún no hay miembros en tu familia.',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final score = scores[member.id] ?? 0;
                    final isMe = member.id == currentUserId;
                    Widget rankBadge;
                    if (index == 0) {
                      rankBadge = const Text(
                        '🥇',
                        style: TextStyle(fontSize: 22),
                      );
                    } else if (index == 1) {
                      rankBadge = const Text(
                        '🥈',
                        style: TextStyle(fontSize: 22),
                      );
                    } else if (index == 2) {
                      rankBadge = const Text(
                        '🥉',
                        style: TextStyle(fontSize: 22),
                      );
                    } else {
                      rankBadge = Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      );
                    }
                    Color itemBg = isMe
                        ? AppTheme.purple700.withValues(alpha: 0.08)
                        : Colors.grey.shade50;
                    Color itemBorder = isMe
                        ? AppTheme.purple700.withValues(alpha: 0.3)
                        : Colors.grey.shade200;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: itemBorder,
                          width: isMe ? 1.5 : 1.0,
                        ),
                        boxShadow: isMe
                            ? [
                                BoxShadow(
                                  color: AppTheme.purple700.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Center(child: rankBadge)),
                          const SizedBox(width: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(member.color.replaceAll('#', '0xFF')),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.avatar,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        member.nombre,
                                        style: TextStyle(
                                          color: AppTheme.textDark,
                                          fontWeight: isMe
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.purple700,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'TÚ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.rol.toUpperCase(),
                                  style: TextStyle(
                                    color: isMe
                                        ? AppTheme.purple700
                                        : AppTheme.textLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppTheme.purple700
                                  : AppTheme.purple700.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score correctas',
                              style: TextStyle(
                                color: isMe ? Colors.white : AppTheme.purple700,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasCompletedRetoOnDay(
    DateTime dayDate,
    String? userId,
    List<Evidence> evidences,
    List<PendingValidation> pending,
    Set<String> completedToday,
  ) {
    if (userId == null) return false;
    final now = DateTime.now();
    final isToday =
        dayDate.day == now.day &&
        dayDate.month == now.month &&
        dayDate.year == now.year;
    if (isToday && completedToday.isNotEmpty) {
      return true;
    }
    final hasEvidence = evidences.any((e) {
      if (e.userId != userId) return false;
      try {
        final dt = DateTime.parse(e.tiempo).toLocal();
        return dt.day == dayDate.day &&
            dt.month == dayDate.month &&
            dt.year == dayDate.year;
      } catch (_) {
        return false;
      }
    });
    if (hasEvidence) return true;
    final hasPending = pending.any((pv) {
      if (pv.userId != userId) return false;
      final dt = DateTime.fromMillisecondsSinceEpoch(pv.id).toLocal();
      return dt.day == dayDate.day &&
          dt.month == dayDate.month &&
          dt.year == dayDate.year;
    });
    return hasPending;
  }
}
