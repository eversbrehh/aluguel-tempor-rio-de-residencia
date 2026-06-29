import 'package:dio/dio.dart';

import '../../../core/http/auth_interceptor.dart';
import '../domain/tarefa.dart';

class TarefaRepository {
  TarefaRepository(this._dio);
  final Dio _dio;

  Future<List<Tarefa>> listar({String? associacaoId, String? imovelId}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/tarefas',
        queryParameters: {
          if (associacaoId != null) 'associacaoId': associacaoId,
          if (imovelId != null) 'imovelId': imovelId,
        },
      );
      final data = (res.data?['data'] as List?) ?? const [];
      return data
          .cast<Map<String, dynamic>>()
          .map(Tarefa.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Tarefa> criar({
    required String associacaoId,
    required String titulo,
    String? descricao,
    String recorrencia = 'unica',
    String? prazo,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/tarefas',
        data: {
          'associacaoId': associacaoId,
          'titulo': titulo,
          if (descricao != null) 'descricao': descricao,
          'recorrencia': recorrencia,
          if (prazo != null) 'prazo': prazo,
        },
      );
      return Tarefa.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Tarefa> concluir(String id) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/tarefas/$id/concluir',
      );
      return Tarefa.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
