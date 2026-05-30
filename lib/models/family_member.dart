class FamilyMember {
  final String id;
  final String nombre;
  final String rol;
  final int xp;
  final int nivel;
  final String avatar;
  final String color;
  final String? avatarUrl;
  final int triviaCorrectCount;
  final String? triviaLastUpdated;

  FamilyMember({
    this.id = '',
    required this.nombre,
    required this.rol,
    required this.xp,
    required this.nivel,
    required this.avatar,
    required this.color,
    this.avatarUrl,
    this.triviaCorrectCount = 0,
    this.triviaLastUpdated,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] ?? '',
    nombre: json['nombre'] ?? 'Usuario',
    rol: json['rol'] ?? 'miembro',
    xp: json['xp'] ?? 0,
    nivel: json['nivel'] ?? 1,
    avatar: json['avatar_letra']?.toString() ?? 'U',
    color: json['avatar_color']?.toString() ?? '#2e7d32',
    avatarUrl: json['avatar_url']?.toString(),
    triviaCorrectCount: json['trivia_correct_count'] ?? 0,
    triviaLastUpdated: json['trivia_last_updated']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'rol': rol,
    'xp': xp,
    'nivel': nivel,
    'avatar_letra': avatar,
    'avatar_color': color,
    'trivia_correct_count': triviaCorrectCount,
    'trivia_last_updated': triviaLastUpdated,
  };

  FamilyMember withAvatarUrl(String? url) => FamilyMember(
    id: id,
    nombre: nombre,
    rol: rol,
    xp: xp,
    nivel: nivel,
    avatar: avatar,
    color: color,
    avatarUrl: url,
    triviaCorrectCount: triviaCorrectCount,
    triviaLastUpdated: triviaLastUpdated,
  );
}
