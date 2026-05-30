import 'dart:convert';
import 'api_client.dart';

class TaskService {
  Future<bool> rewardUser(String userId, int xpToAdd, int monedasToAdd) async {
    final response = await ApiClient().post('/auth/profile/reward', {
      'xpToAdd': xpToAdd,
      'coinsToAdd': monedasToAdd,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['leveledUp'] as bool? ?? false;
    } else {
      throw Exception('Error al registrar recompensa del usuario.');
    }
  }
}
