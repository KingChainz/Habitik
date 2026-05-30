class PendingValidation {
  final int id;
  final String userId;
  final String usuario;
  final String avatar;
  final String color;
  final String reto;
  final String hora;
  final int xp;
  final int monedas;
  final List<String> evidencias;
  final bool requiereEvidencia;

  PendingValidation({
    required this.id,
    required this.userId,
    required this.usuario,
    required this.avatar,
    required this.color,
    required this.reto,
    required this.hora,
    required this.xp,
    required this.monedas,
    required this.evidencias,
    required this.requiereEvidencia,
  });

  factory PendingValidation.fromJson(Map<String, dynamic> json) =>
      PendingValidation(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? '',
        usuario: json['usuario'] ?? '',
        avatar: json['avatar'] ?? 'U',
        color: json['color'] ?? '#000000',
        reto: json['reto'] ?? '',
        hora: json['hora'] ?? '',
        xp: json['xp'] ?? 0,
        monedas: json['monedas'] ?? 0,
        evidencias: List<String>.from(json['evidencias'] ?? []),
        requiereEvidencia: json['requiere_evidencia'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'usuario': usuario,
    'avatar': avatar,
    'color': color,
    'reto': reto,
    'hora': hora,
    'xp': xp,
    'monedas': monedas,
    'evidencias': evidencias,
    'requiere_evidencia': requiereEvidencia,
  };
}
