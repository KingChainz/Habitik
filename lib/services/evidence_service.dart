import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';

class EvidenceService {
  Future<List<Evidence>> getEvidences(String familyId) async {
    final response = await ApiClient().get('/evidences?familyId=$familyId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((d) {
        return Evidence(
          id: d['id'] ?? '',
          userId: d['userId'],
          familyId: d['familyId'],
          autor: d['autor'] ?? 'Usuario',
          avatar: d['avatar'] ?? 'U',
          color: d['color'] ?? '#2e7d32',
          avatarUrl: d['avatarUrl'],
          accion: d['accion'] ?? '',
          desc: d['desc'] ?? '',
          likes: d['likes'] ?? 0,
          tiempo: d['tiempo'] ?? '',
          xp: d['xp'] ?? 0,
          emoji: d['emoji'] ?? '🌟',
          imagen: d['imagen'],
        );
      }).toList();
    } else {
      throw Exception('Error al obtener feed de evidencias.');
    }
  }

  Future<void> createEvidence({
    required String familyId,
    required String userId,
    required String accion,
    required String descripcion,
    String? urlImagen,
  }) async {
    final response = await ApiClient().post('/evidences', {
      'familyId': familyId,
      'userId': userId,
      'accion': accion,
      'desc': descripcion,
      'imagen': urlImagen,
    });
    if (response.statusCode != 201) {
      throw Exception('Error al crear evidencia.');
    }
  }

  Future<void> toggleLike(
    String evidenceId,
    String userId,
    bool isLiked,
  ) async {
    final suffix = isLiked ? 'unlike' : 'like';
    final response = await ApiClient().post('/evidences/$evidenceId/$suffix', {});
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar like.');
    }
  }
}
