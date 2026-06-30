import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../env.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = AuthService.instance.token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});

String _extractError(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    return data['error']?.toString() ?? e.message ?? 'Request failed';
  }
  if (data is String && data.isNotEmpty) {
    return data.length > 120 ? '${data.substring(0, 120)}...' : data;
  }
  return e.message ?? 'Request failed';
}

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.post(path, data: body);
      if (res.data == null || res.data == '') return {};
      return _asMap(res.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.patch(path, data: body);
      return _asMap(res.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected server response');
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
