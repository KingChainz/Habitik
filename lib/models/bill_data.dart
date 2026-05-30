class BillData {
  final String id;
  final String? familyId;
  final String tipo;
  final String consumo;
  final String monto;
  final String periodo;
  final String? empresa;
  final String? cuenta;
  final String? tarifa;
  final String? imagenUrl;

  BillData({
    this.id = '',
    this.familyId,
    this.tipo = 'luz',
    required this.consumo,
    required this.monto,
    required this.periodo,
    required this.empresa,
    required this.cuenta,
    required this.tarifa,
    this.imagenUrl,
  });

  factory BillData.fromJson(Map<String, dynamic> json) => BillData(
    id: json['id']?.toString() ?? '',
    familyId: json['family_id']?.toString(),
    tipo: json['tipo']?.toString() ?? 'luz',
    consumo: json['consumo']?.toString() ?? '',
    monto: json['monto']?.toString() ?? '',
    periodo: json['periodo']?.toString() ?? '',
    empresa: json['empresa']?.toString() ?? '',
    cuenta: json['cuenta']?.toString() ?? '',
    tarifa: json['tarifa']?.toString() ?? '',
    imagenUrl: json['imagen_url']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (familyId != null) 'family_id': familyId,
    'tipo': tipo,
    'consumo': consumo,
    'monto': monto,
    'periodo': periodo,
    'empresa': empresa,
    'cuenta': cuenta,
    'tarifa': tarifa,
    if (imagenUrl != null) 'imagen_url': imagenUrl,
  };
}
