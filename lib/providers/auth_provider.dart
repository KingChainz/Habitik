import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthService get authService => _authService;

  bool _onboardingActive = false;
  bool get onboardingActive => _onboardingActive;

  void setOnboardingActive(bool v) {
    _onboardingActive = v;
    notifyListeners();
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient().getToken();
    if (token != null) {
      try {
        final p = await _authService.getCurrentProfile();
        if (p != null) {
          _profile = await _loadProfileWithCache(p);
          _user = User(id: p.id, email: p.email);
        } else {
          await ApiClient().clearToken();
        }
      } catch (_) {
        await ApiClient().clearToken();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<UserProfile?> _loadProfileWithCache(UserProfile? p) async {
    if (p == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('avatar_url_${p.id}');
    if (cachedUrl != null) {
      return p.copyWith(avatarUrl: cachedUrl);
    }
    return p;
  }

  Future<void> signInWithEmail(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _authService.signInWithEmail(email, password);
      if (_profile != null) {
        _user = User(id: _profile!.id, email: _profile!.email);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deductCoins(int cost) async {
    if (_profile == null) return;
    try {
      await _authService.deductCoins(_profile!.id, _profile!.monedas, cost);
      _profile = await _authService.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    _error = null;
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String nombre) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _authService.signUp(email, password, nombre);
      if (_profile != null) {
        _user = User(id: _profile!.id, email: _profile!.email);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    var p = await _authService.getCurrentProfile();
    if (p != null) {
      final prefs = await SharedPreferences.getInstance();
      final cachedUrl = prefs.getString('avatar_url_${p.id}');
      if (cachedUrl != null) p = p.copyWith(avatarUrl: cachedUrl);
    }
    _profile = p;
    notifyListeners();
  }

  Future<void> updateTriviaScore(int count) async {
    if (_profile == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      await _authService.updateTriviaScore(_profile!.id, count, today);
      _profile = _profile!.copyWith(
        triviaCorrectCount: count,
        triviaLastUpdated: today,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating remote trivia score: $e');
    }
  }

  Future<void> updateDailyBonusClaimedAt(String date) async {
    if (_profile == null) return;
    try {
      await _authService.updateDailyBonusClaimedAt(_profile!.id, date);
      _profile = _profile!.copyWith(dailyBonusClaimedAt: date);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating remote daily bonus: $e');
    }
  }

  void setLocalAvatarUrl(String url) {
    if (_profile == null) return;
    _profile = _profile!.copyWith(avatarUrl: url);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
