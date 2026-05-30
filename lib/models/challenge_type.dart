class ChallengeType {
  final String id;
  final String emoji;
  final String titulo;
  final String desc;
  final int xp;
  final int monedas;
  final String color;

  ChallengeType({
    required this.id,
    required this.emoji,
    required this.titulo,
    required this.desc,
    required this.xp,
    required this.monedas,
    required this.color,
  });

  factory ChallengeType.fromJson(Map<String, dynamic> json) => ChallengeType(
    id: json['id']?.toString() ?? '',
    emoji: json['emoji'] ?? '🎯',
    titulo: json['titulo'] ?? '',
    desc: json['desc'] ?? '',
    xp: json['xp'] ?? 0,
    monedas: json['monedas'] ?? 0,
    color: json['color'] ?? '#000000',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'titulo': titulo,
    'desc': desc,
    'xp': xp,
    'monedas': monedas,
    'color': color,
  };
}
