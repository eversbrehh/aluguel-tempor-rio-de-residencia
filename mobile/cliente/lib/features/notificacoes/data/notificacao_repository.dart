import 'package:dio/dio.dart';

import '../../../core/http/auth_interceptor.dart';
import '../domain/notificacao.dart';

class NotificacaoRepository {
  NotificacaoRepository(this._dio);
  final Dio _dio;

  Future<NotificacoesListResult> listar({int limit = 30}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/notificacoes',
        queryParameters: {'limit': limit},
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      final itens = ((data?['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Notificacao.fromJson)
          .toList(growable: false);
      final naoLidas = (data?['unreadCount'] as num?)?.toInt() ?? 0;
      return NotificacoesListResult(itens: itens, naoLidas: naoLidas);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> marcarTodasComoLidas() async {
    try {
      await _dio.patch<Map<String, dynamic>>('/notificacoes/lidas');
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> marcarComoLida(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/notificacoes/$id/lida');
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
