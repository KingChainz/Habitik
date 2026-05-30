class Evidence {
  final String id;
  final String? userId;
  final String? familyId;
  final String autor;
  final String avatar;
  final String color;
  final String? avatarUrl;
  final String accion;
  final String desc;
  int likes;
  final String tiempo;
  final int xp;
  final String emoji;
  final String? imagen;

  Evidence({
    this.id = '',
    this.userId,
    this.familyId,
    required this.autor,
    required this.avatar,
    required this.color,
    this.avatarUrl,
    required this.accion,
    required this.desc,
    required this.likes,
    required this.tiempo,
    required this.xp,
    required this.emoji,
    this.imagen,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'] ?? '',
    userId: json['user_id'],
    familyId: json['family_id'],
    autor: json['autor'] ?? '',
    avatar: json['avatar'] ?? 'U',
    color: json['color'] ?? '#2e7d32',
    accion: json['accion'] ?? '',
    desc: json['descripcion'] ?? '',
    likes: json['likes'] ?? 0,
    tiempo: json['created_at'] ?? '',
    xp: json['xp'] ?? 0,
    emoji: json['emoji'] ?? '🌟',
    imagen: json['imagen_url'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (userId != null) 'user_id': userId,
    if (familyId != null) 'family_id': familyId,
    'autor': autor,
    'avatar': avatar,
    'color': color,
    'accion': accion,
    'descripcion': desc,
    'likes': likes,
    'created_at': tiempo,
    'xp': xp,
    'emoji': emoji,
    if (imagen != null) 'imagen_url': imagen,
  };
}
