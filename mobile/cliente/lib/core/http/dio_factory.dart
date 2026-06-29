import 'package:dio/dio.dart';

import '../env/app_env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Cria um [Dio] configurado com base url, timeouts e interceptor de auth.
Dio buildDio({
  required String baseUrl,
  required TokenStorage storage,
  Future<void> Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppEnv.httpTimeout,
      receiveTimeout: AppEnv.httpTimeout,
      sendTimeout: AppEnv.httpTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(storage, onUnauthorized: onUnauthorized),
  );
  return dio;
}
