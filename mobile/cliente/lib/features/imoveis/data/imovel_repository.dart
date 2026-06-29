import 'package:dio/dio.dart';

import '../../../core/http/auth_interceptor.dart';
import '../domain/imovel.dart';

class ImovelRepository {
  ImovelRepository(this._dio);
  final Dio _dio;

  Future<List<Imovel>> listarMeus() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/imoveis/meus');
      final data = (res.data?['data'] as List?) ?? const [];
      return data
          .cast<Map<String, dynamic>>()
          .map(Imovel.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Imovel> obter(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/imoveis/$id');
      return Imovel.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<Associacao>> associacoes(String imovelId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/imoveis/$imovelId/associacoes',
      );
      final data = (res.data?['data'] as List?) ?? const [];
      return data
          .cast<Map<String, dynamic>>()
          .map(Associacao.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Imovel> criar({
    required String titulo,
    required String endereco,
    String? descricao,
    double? valorAluguel,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/imoveis',
        data: {
          'titulo': titulo,
          'endereco': endereco,
          if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
          if (valorAluguel != null) 'valorAluguel': valorAluguel,
        },
      );
      return Imovel.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Associacao> associarComodatario({
    required String imovelId,
    required String comodatarioEmail,
    required String dataInicio,
    String? dataFim,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/imoveis/$imovelId/associacoes',
        data: {
          'comodatarioEmail': comodatarioEmail,
          'dataInicio': dataInicio,
          if (dataFim != null && dataFim.isNotEmpty) 'dataFim': dataFim,
        },
      );
      return Associacao.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> encerrarAssociacao({
    required String imovelId,
    required String associacaoId,
    String? dataFim,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/imoveis/$imovelId/associacoes/$associacaoId/encerrar',
        data: dataFim != null && dataFim.isNotEmpty
            ? {'dataFim': dataFim}
            : <String, dynamic>{},
      );
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
