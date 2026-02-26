import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/auth_api_service.dart';
import '../../domain/auth_state.dart';

final secureStorageProvider = Provider<SecureStorageService>((_) {
  return const SecureStorageService(FlutterSecureStorage());
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.read(authDioProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      ref.read(authApiServiceProvider),
      ref.read(secureStorageProvider),
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  final AuthApiService _authApi;
  final SecureStorageService _storage;

  AuthController(this._authApi, this._storage) : super(const AuthState());

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final token = await _storage.readToken();
    state = state.copyWith(isLoading: false, token: token, clearError: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _authApi.login(email: email, password: password);
      await _storage.saveToken(token);
      state = state.copyWith(isLoading: false, token: token, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _authApi.register(email: email, password: password);
      await _storage.saveToken(token);
      state = state.copyWith(isLoading: false, token: token, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();
    state = const AuthState();
  }
}
