class RewardItem {
  final int id;
  final String? familyId;
  final String titulo;
  final int costo;
  final String descripcion;
  final String emoji;
  bool disponible;
  final String creador;
  DateTime? lastRedeemedAt;

  RewardItem({
    required this.id,
    this.familyId,
    required this.titulo,
    required this.costo,
    required this.descripcion,
    this.emoji = '🎁',
    required this.disponible,
    required this.creador,
    this.lastRedeemedAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
    id: json['id'] ?? 0,
    familyId: json['family_id'],
    titulo: json['titulo'] ?? '',
    costo: json['costo'] ?? 0,
    descripcion: json['descripcion'] ?? '',
    emoji: json['emoji'] ?? '🎁',
    disponible: json['disponible'] ?? true,
    creador: json['creador_id'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'titulo': titulo,
    'costo': costo,
    'descripcion': descripcion,
    'emoji': emoji,
    'disponible': disponible,
    'creador_id': creador,
  };
}
