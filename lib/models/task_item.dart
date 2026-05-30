class TaskItem {
  final String id;
  final String? familyId;
  String tarea;
  String asignado;
  bool hecho;
  int xp;
  String tipo;

  TaskItem({
    required this.id,
    this.familyId,
    required this.tarea,
    required this.asignado,
    required this.hecho,
    required this.xp,
    required this.tipo,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    id: json['id']?.toString() ?? '',
    familyId: json['family_id']?.toString(),
    tarea: json['tarea']?.toString() ?? '',
    asignado: json['asignado_id']?.toString() ?? '',
    hecho:
        json['hecho'] == true || json['hecho'] == 1 || json['hecho'] == 'true',
    xp: int.tryParse(json['xp']?.toString() ?? '0') ?? 0,
    tipo: json['tipo']?.toString() ?? 'general',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'tarea': tarea,
    'asignado_id': asignado,
    'hecho': hecho,
    'xp': xp,
    'tipo': tipo,
  };
}
