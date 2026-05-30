class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final String avatarLetra;
  final String avatarColor;
  final String? avatarUrl;
  final String rol;
  final String? familyId;
  final int xp;
  final int nivel;
  final int monedas;
  final int triviaCorrectCount;
  final String? triviaLastUpdated;
  final String? dailyBonusClaimedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    required this.avatarLetra,
    required this.avatarColor,
    this.avatarUrl,
    required this.rol,
    this.familyId,
    this.xp = 0,
    this.nivel = 1,
    this.monedas = 0,
    this.triviaCorrectCount = 0,
    this.triviaLastUpdated,
    this.dailyBonusClaimedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    nombre: json['nombre'] ?? 'Usuario',
    avatarLetra: json['avatar_letra'] ?? 'U',
    avatarColor: json['avatar_color'] ?? '#2e7d32',
    avatarUrl: json['avatar_url'],
    rol: json['rol'] ?? 'miembro',
    familyId: json['family_id'],
    xp: json['xp'] ?? 0,
    nivel: json['nivel'] ?? 1,
    monedas: json['monedas'] ?? 0,
    triviaCorrectCount: json['trivia_correct_count'] ?? 0,
    triviaLastUpdated: json['trivia_last_updated']?.toString(),
    dailyBonusClaimedAt: json['daily_bonus_claimed_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nombre': nombre,
    'avatar_letra': avatarLetra,
    'avatar_color': avatarColor,
    'avatar_url': avatarUrl,
    'rol': rol,
    'family_id': familyId,
    'xp': xp,
    'nivel': nivel,
    'monedas': monedas,
    'trivia_correct_count': triviaCorrectCount,
    'trivia_last_updated': triviaLastUpdated,
    'daily_bonus_claimed_at': dailyBonusClaimedAt,
  };

  UserProfile copyWith({
    String? id,
    String? email,
    String? nombre,
    String? avatarLetra,
    String? avatarColor,
    String? avatarUrl,
    String? rol,
    String? familyId,
    int? xp,
    int? nivel,
    int? monedas,
    int? triviaCorrectCount,
    String? triviaLastUpdated,
    String? dailyBonusClaimedAt,
  }) => UserProfile(
    id: id ?? this.id,
    email: email ?? this.email,
    nombre: nombre ?? this.nombre,
    avatarLetra: avatarLetra ?? this.avatarLetra,
    avatarColor: avatarColor ?? this.avatarColor,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    rol: rol ?? this.rol,
    familyId: familyId ?? this.familyId,
    xp: xp ?? this.xp,
    nivel: nivel ?? this.nivel,
    monedas: monedas ?? this.monedas,
    triviaCorrectCount: triviaCorrectCount ?? this.triviaCorrectCount,
    triviaLastUpdated: triviaLastUpdated ?? this.triviaLastUpdated,
    dailyBonusClaimedAt: dailyBonusClaimedAt ?? this.dailyBonusClaimedAt,
  );
}

class User {
  final String id;
  final String email;
  User({required this.id, required this.email});
}
