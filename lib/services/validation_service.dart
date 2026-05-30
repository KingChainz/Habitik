import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';

class ValidationService {
  Future<void> insertValidation(PendingValidation pv, String familyId) async {
    final response = await ApiClient().post('/validations', {
      'familyId': familyId,
      'userId': pv.userId,
      'usuario': pv.usuario,
      'avatar': pv.avatar,
      'color': pv.color,
      'reto': pv.reto,
      'hora': pv.hora,
      'xp': pv.xp,
      'monedas': pv.monedas,
      'evidencias': pv.evidencias,
      'requiereEvidencia': pv.requiereEvidencia,
    });
    if (response.statusCode != 201) {
      throw Exception('Error al enviar validación al servidor.');
    }
  }

  Future<List<PendingValidation>> getPendingForFamily(String familyId) async {
    final response = await ApiClient().get('/validations?familyId=$familyId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((d) {
        return PendingValidation.fromJson({
          ...d,
          'id': d['id'] is int ? d['id'] as int : int.parse(d['id'].toString()),
          'user_id': d['userId'] ?? d['user_id'],
          'requiere_evidencia': d['requiereEvidencia'] ?? d['requiere_evidencia'],
        });
      }).toList();
    } else {
      throw Exception('Error al obtener validaciones del servidor.');
    }
  }

  Future<List<Map<String, dynamic>>> getRetosForUserToday(String userId) async {
    final response = await ApiClient().get('/validations/today?userId=$userId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener retos del día.');
    }
  }

  Future<void> markApproved(int validationId) async {
    final response = await ApiClient().post('/validations/$validationId/approve', {});
    if (response.statusCode != 200) {
      throw Exception('Error al aprobar validación en el servidor.');
    }
  }

  Future<void> markRejected(int validationId) async {
    final response = await ApiClient().post('/validations/$validationId/reject', {});
    if (response.statusCode != 200) {
      throw Exception('Error al rechazar validación en el servidor.');
    }
  }

  Future<void> deleteValidation(int validationId) async {
    await ApiClient().delete('/validations/$validationId');
  }

  Stream<List<PendingValidation>> streamPendingForFamily(String familyId) async* {
    while (true) {
      try {
        final list = await getPendingForFamily(familyId);
        yield list;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 8));
    }
  }
}
