import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/app_exception.dart';

class AuthApiService {
  final Dio _dio;

  const AuthApiService(this._dio);

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/login',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'x-api-key': ApiConstants.reqResApiKey},
        ),
      );
      final token = response.data?['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AppException('Token missing in login response');
      }
      return token;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['error']?.toString() ?? 'Login failed')
          : 'Login failed';
      throw AppException(message);
    }
  }

  Future<String> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/register',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'x-api-key': ApiConstants.reqResApiKey},
        ),
      );
      final token = response.data?['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AppException('Token missing in register response');
      }
      return token;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['error']?.toString() ?? 'Registration failed')
          : 'Registration failed';
      throw AppException(message);
    }
  }
}
