import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  Future<UserProfile?> signInWithEmail(String email, String password) async {
    final response = await ApiClient().post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      await ApiClient().setToken(token);
      return UserProfile.fromJson(data['profile']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Error al iniciar sesión.');
    }
  }

  Future<void> signInWithGoogle() async {
    throw UnsupportedError('Inicio de sesión con Google no soportado.');
  }

  Future<UserProfile?> signUp(
    String email,
    String password,
    String nombre,
  ) async {
    final response = await ApiClient().post('/auth/register', {
      'email': email,
      'password': password,
      'nombre': nombre,
    });
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      await ApiClient().setToken(token);
      return UserProfile.fromJson(data['profile']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Error al registrarse.');
    }
  }

  Future<void> signOut() async {
    await ApiClient().clearToken();
  }

  Future<UserProfile?> getCurrentProfile() async {
    final response = await ApiClient().get('/auth/profile');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data);
    }
    return null;
  }

  Future<void> deductCoins(String userId, int currentCoins, int cost) async {
    final response = await ApiClient().post('/auth/profile/reward', {
      'xpToAdd': 0,
      'coinsToAdd': -cost,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar monedas.');
    }
  }

  Future<void> updateTriviaScore(
    String userId,
    int count,
    String todayDate,
  ) async {
    final response = await ApiClient().post('/auth/profile/xp-monedas', {
      'triviaCorrectCount': count,
      'triviaLastUpdated': todayDate,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar puntuación de trivia.');
    }
  }

  Future<void> updateDailyBonusClaimedAt(String userId, String date) async {
    final response = await ApiClient().post('/auth/profile/bonus', {
      'claimedAt': date,
      'xpToAdd': 0,
      'coinsToAdd': 0,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar bono diario.');
    }
  }
}

class FamilyService {
  Future<String?> createFamily(String userId, int personas) async {
    final response = await ApiClient().post('/families/create', {
      'nombre': 'Mi Hogar',
    });
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['family']['id'] as String?;
    } else {
      throw Exception('Error al crear grupo familiar.');
    }
  }

  Future<Map<String, dynamic>> getOrGenerateActiveQRToken(
    String familyId, {
    bool forceNew = false,
  }) async {
    final response = await ApiClient().post('/families/$familyId/qr', {
      'forceNew': forceNew,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'token': data['token'],
        'timeLeft': data['timeLeft'],
      };
    } else {
      throw Exception('Error al obtener token QR.');
    }
  }

  Future<String?> generateQRToken(String familyId) async {
    final res = await getOrGenerateActiveQRToken(familyId);
    return res['token'] as String?;
  }

  Future<String?> validateFamilyCode(String code) async {
    final response = await ApiClient().post('/families/validate-code', {
      'code': code,
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['familyId'] as String?;
    }
    return null;
  }

  Future<void> linkMember(String userId, String familyId) async {
    final response = await ApiClient().post('/families/join', {
      'familyId': familyId,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al unirse al grupo familiar.');
    }
  }

  Future<void> updateMetas(String familyId, int metaLuz, int metaAgua) async {
    final response = await ApiClient().put('/families/metas', {
      'familyId': familyId,
      'metaLuz': metaLuz,
      'metaAgua': metaAgua,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar metas.');
    }
  }

  Future<Map<String, dynamic>?> getFamilyDetails(String familyId) async {
    final response = await ApiClient().get('/families/details?familyId=$familyId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>?;
    }
    return null;
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final response = await ApiClient().get('/families/members?familyId=$familyId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((d) {
        return FamilyMember.fromJson({
          ...d,
          'avatar_letra': d['avatar_letra'] ?? d['avatar'] ?? 'U',
          'avatar_color': d['avatar_color'] ?? d['color'] ?? '#2e7d32',
        });
      }).toList();
    } else {
      throw Exception('Error al obtener miembros de la familia.');
    }
  }

  Future<void> deductCoins(String userId, int currentCoins, int cost) async {
    final response = await ApiClient().post('/auth/profile/reward', {
      'xpToAdd': 0,
      'coinsToAdd': -cost,
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar monedas.');
    }
  }
}
