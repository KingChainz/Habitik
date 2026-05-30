class AchievementItem {
  final String key;
  final String nombre;
  final String desc;
  final String emoji;
  final String dificultad;
  final int xp;
  final int monedas;
  final bool desbloqueado;
  final String? desbloqueadoEn;

  AchievementItem({
    required this.key,
    required this.nombre,
    required this.desc,
    required this.emoji,
    required this.dificultad,
    required this.xp,
    required this.monedas,
    this.desbloqueado = false,
    this.desbloqueadoEn,
  });

  AchievementItem copyWith({bool? desbloqueado, String? desbloqueadoEn}) =>
      AchievementItem(
        key: key,
        nombre: nombre,
        desc: desc,
        emoji: emoji,
        dificultad: dificultad,
        xp: xp,
        monedas: monedas,
        desbloqueado: desbloqueado ?? this.desbloqueado,
        desbloqueadoEn: desbloqueadoEn ?? this.desbloqueadoEn,
      );

  factory AchievementItem.fromJson(Map<String, dynamic> json) =>
      AchievementItem(
        key: json['logro_key'] ?? '',
        nombre: json['nombre'] ?? '',
        desc: json['desc'] ?? '',
        emoji: json['emoji'] ?? '🏆',
        dificultad: json['dificultad'] ?? 'fácil',
        xp: json['xp'] ?? 0,
        monedas: json['monedas'] ?? 0,
        desbloqueado: json['desbloqueado'] ?? false,
        desbloqueadoEn: json['desbloqueado_en'],
      );

  Map<String, dynamic> toJson() => {
    'logro_key': key,
    'nombre': nombre,
    'desc': desc,
    'emoji': emoji,
    'dificultad': dificultad,
    'xp': xp,
    'monedas': monedas,
    'desbloqueado': desbloqueado,
    'desbloqueado_en': desbloqueadoEn,
  };
}
