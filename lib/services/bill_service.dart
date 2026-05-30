import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';

class BillService {
  Future<List<BillData>> getBills(String familyId) async {
    final response = await ApiClient().get('/bills?familyId=$familyId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((d) => BillData.fromJson(d)).toList();
    } else {
      throw Exception('Error al obtener boletas del servidor.');
    }
  }

  Future<void> createBill(BillData bill) async {
    final response = await ApiClient().post('/bills', {
      'familyId': bill.familyId,
      'tipo': bill.tipo,
      'consumo': bill.consumo,
      'monto': bill.monto,
      'periodo': bill.periodo,
      'empresa': bill.empresa,
      'cuenta': bill.cuenta,
      'tarifa': bill.tarifa,
      'imagen_url': bill.imagenUrl,
    });
    if (response.statusCode != 201) {
      throw Exception('Error al registrar boleta en el servidor.');
    }
  }

  Future<void> deleteBill(String id) async {
    final response = await ApiClient().delete('/bills/$id');
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar boleta del servidor.');
    }
  }
}
