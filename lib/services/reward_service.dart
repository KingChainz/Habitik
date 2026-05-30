import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import 'api_client.dart';

class RewardService {
  Future<List<RewardItem>> getRewards(String familyId) async {
    final response = await ApiClient().get('/rewards?familyId=$familyId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return _parseList(data);
    } else {
      throw Exception('Error al obtener lista de premios.');
    }
  }

  Stream<List<RewardItem>> streamRewards(String familyId) async* {
    while (true) {
      try {
        final list = await getRewards(familyId);
        yield list;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 8));
    }
  }

  List<RewardItem> _parseList(List rows) => rows
      .map(
        (e) => RewardItem(
          id: e['id'] is int ? e['id'] as int : int.parse(e['id'].toString()),
          titulo: e['titulo'] as String,
          descripcion: e['descripcion'] as String? ?? '',
          emoji: e['emoji'] as String? ?? '🎁',
          costo: e['costo'] as int? ?? 100,
          disponible: e['disponible'] as bool? ?? true,
          creador: e['creador']?.toString() ?? '',
          lastRedeemedAt: e['lastRedeemedAt'] != null
              ? DateTime.tryParse(e['lastRedeemedAt'] as String)
              : null,
        ),
      )
      .toList();

  Future<void> seedDefaults(String familyId) async {
    final existing = await getRewards(familyId);
    if (existing.isNotEmpty) return;
    final defaults = [
      {
        'id': 1,
        'titulo': 'Cena favorita',
        'descripcion': 'Elige la cena del viernes',
        'emoji': '🍕',
        'costo': 200,
        'disponible': true,
        'creador': 'Jefe',
      },
      {
        'id': 2,
        'titulo': 'Día sin tareas',
        'descripcion': 'Un día libre de tareas del hogar',
        'emoji': '🛌',
        'costo': 350,
        'disponible': true,
        'creador': 'Jefe',
      },
      {
        'id': 3,
        'titulo': 'Salida al cine',
        'descripcion': 'Boletos para toda la familia',
        'emoji': '🎬',
        'costo': 500,
        'disponible': true,
        'creador': 'Jefe',
      },
      {
        'id': 4,
        'titulo': 'Hora extra videojuegos',
        'descripcion': '30 min adicionales',
        'emoji': '🎮',
        'costo': 150,
        'disponible': true,
        'creador': 'Jefe',
      },
    ];
    for (final d in defaults) {
      await upsertReward(
        RewardItem(
          id: d['id'] as int,
          titulo: d['titulo'] as String,
          descripcion: d['descripcion'] as String,
          emoji: d['emoji'] as String,
          costo: d['costo'] as int,
          disponible: d['disponible'] as bool,
          creador: d['creador'] as String,
        ),
        familyId,
      );
    }
  }

  Future<void> upsertReward(RewardItem r, String familyId) async {
    final response = await ApiClient().post('/rewards', {
      'id': r.id,
      'familyId': familyId,
      'titulo': r.titulo,
      'descripcion': r.descripcion,
      'emoji': r.emoji,
      'costo': r.costo,
      'disponible': r.disponible,
      'creador': r.creador,
      'lastRedeemedAt': r.lastRedeemedAt?.toIso8601String(),
    });
    if (response.statusCode != 201) {
      throw Exception('Error al guardar el premio.');
    }
  }

  Future<void> deleteReward(int id) async {
    final response = await ApiClient().delete('/rewards/$id');
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar premio.');
    }
  }

  Future<void> markRedeemed(int id, {required bool disponible}) async {
    final response = await ApiClient().put('/rewards/$id', {
      'disponible': disponible,
      'lastRedeemedAt': disponible ? null : DateTime.now().toIso8601String(),
    });
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar disponibilidad del premio.');
    }
  }

  Future<void> resetDailyAvailability(String familyId) async {
    final today = DateTime.now();
    final rewards = await getRewards(familyId);
    for (final r in rewards) {
      if (!r.disponible && r.lastRedeemedAt != null) {
        final rd = r.lastRedeemedAt!;
        if (rd.year != today.year ||
            rd.month != today.month ||
            rd.day != today.day) {
          await markRedeemed(r.id, disponible: true);
        }
      }
    }
  }

  Future<void> createRedemption(
    String userId,
    String familyId,
    String titulo,
    int costo,
  ) async {
    final response = await ApiClient().post('/validations', {
      'familyId': familyId,
      'userId': userId,
      'reto': 'Canjear: $titulo',
      'monedas': -costo,
    });
    if (response.statusCode != 201) {
      throw Exception('Error al crear registro de canje.');
    }
  }

  Future<List<Map<String, dynamic>>> getRedemptionHistory(String userId) async {
    final response = await ApiClient().get('/rewards/history');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => {
        'titulo': e['titulo'] as String,
        'costo': e['costo'] as int,
        'fecha': DateTime.tryParse(e['created_at'] as String? ?? '') ?? DateTime.now(),
      }).toList();
    } else {
      throw Exception('Error al obtener historial de canjes.');
    }
  }
}
