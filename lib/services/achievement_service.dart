import 'dart:convert';
import 'api_client.dart';

class AchievementService {
  Future<List<Map<String, dynamic>>> getUnlockedAchievements(
    String userId,
  ) async {
    final response = await ApiClient().get('/achievements?userId=$userId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener logros del servidor.');
    }
  }

  Future<void> unlockAchievement(String userId, String key) async {
    final response = await ApiClient().post('/achievements/unlock', {'key': key});
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Error al registrar logro en el servidor.');
    }
  }
}
