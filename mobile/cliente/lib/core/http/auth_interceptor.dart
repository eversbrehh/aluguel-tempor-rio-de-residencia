import 'package:dio/dio.dart';

import '../errors/failures.dart';
import '../storage/token_storage.dart';

/// Interceptor que injeta `Authorization: Bearer <token>` em todas as chamadas
/// e mapeia 401 para `UnauthorizedFailure`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.onUnauthorized});

  final TokenStorage _storage;
  final Future<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Converte exceções do Dio em [AppFailure] amigáveis.
AppFailure mapDioError(Object err) {
  if (err is DioException) {
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final serverMsg = _extractMessage(data);
    if (status == 401) {
      return UnauthorizedFailure(serverMsg ?? 'Não autorizado');
    }
    if (status != null && status >= 400 && status < 500) {
      return ValidationFailure(serverMsg ?? 'Requisição inválida');
    }
    if (status != null && status >= 500) {
      return ServerFailure(serverMsg ?? 'Erro do servidor', status: status);
    }
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure(
        'Sem conexão com o servidor. Verifique sua internet.',
      );
    }
    return UnknownFailure(err.message ?? 'Erro desconhecido');
  }
  if (err is AppFailure) return err;
  return UnknownFailure(err.toString());
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final m = error['message'];
      if (m is String) return m;
      if (m is Map) return m.values.join(', ');
    }
    if (data['message'] is String) return data['message'] as String;
  }
  return null;
}
