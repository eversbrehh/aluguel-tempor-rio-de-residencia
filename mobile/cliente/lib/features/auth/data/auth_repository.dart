import 'package:dio/dio.dart';

import '../../../core/http/auth_interceptor.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_user.dart';

/// Cliente do monolito para autenticação.
class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  /// POST /auth/login + GET /auth/me.
  Future<AuthUser> login({required String email, required String password}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw const ValidationFailureLite('Resposta inválida do servidor.');
      }
      final token = data['accessToken'] as String;
      final userId = data['userId'] as String;
      await _storage.save(accessToken: token, userId: userId, email: email);
      return _fetchMe(token, fallbackEmail: email, fallbackId: userId);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  /// POST /auth/register seguido de login automático.
  Future<AuthUser> register({
    required String nome,
    required String email,
    required String password,
    required String tipo,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'nome': nome, 'email': email, 'password': password, 'tipo': tipo},
      );
      return login(email: email, password: password);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() => _storage.clear();

  /// Tenta recuperar usuário persistido, validando o token no servidor (GET /auth/me).
  Future<AuthUser?> currentUser() async {
    final token = await _storage.readAccessToken();
    final id = await _storage.readUserId();
    final email = await _storage.readEmail();
    if (token == null || id == null || email == null) return null;
    try {
      return await _fetchMe(token, fallbackEmail: email, fallbackId: id);
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  Future<AuthUser> _fetchMe(
    String token, {
    required String fallbackEmail,
    required String fallbackId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final body = res.data?['data'] as Map<String, dynamic>?;
    return AuthUser(
      id: (body?['id'] as String?) ?? fallbackId,
      email: (body?['email'] as String?) ?? fallbackEmail,
      nome: (body?['nome'] as String?) ?? '',
      tipo: (body?['tipo'] as String?) ?? 'comodatario',
      accessToken: token,
    );
  }
}

/// Pequena exceção local — evita import circular do failures aqui.
class ValidationFailureLite implements Exception {
  const ValidationFailureLite(this.message);
  final String message;
  @override
  String toString() => message;
}
