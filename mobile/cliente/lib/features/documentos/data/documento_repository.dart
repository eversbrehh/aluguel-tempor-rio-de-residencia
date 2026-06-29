import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/http/auth_interceptor.dart';
import '../domain/documento.dart';

class DocumentoRepository {
  DocumentoRepository(this._dio);
  final Dio _dio;

  Future<List<Documento>> listar({String? associacaoId}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/documentos',
        queryParameters: {
          if (associacaoId != null) 'associacaoId': associacaoId,
        },
      );
      final data = (res.data?['data'] as List?) ?? const [];
      return data
          .cast<Map<String, dynamic>>()
          .map(Documento.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Documento> solicitar({
    required String associacaoId,
    required String tipo,
    required String titulo,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/documentos',
        data: {'associacaoId': associacaoId, 'tipo': tipo, 'titulo': titulo},
      );
      return Documento.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Documento> upload({
    required String documentoId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/documentos/$documentoId/upload',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Documento.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<String> downloadUrl(String documentoId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/documentos/$documentoId/download',
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      return (data?['url'] as String?) ?? '';
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Documento> aprovar(String documentoId) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/documentos/$documentoId/aprovar',
      );
      return Documento.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Documento> rejeitar(String documentoId, {String? observacao}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/documentos/$documentoId/rejeitar',
        data: {if (observacao != null) 'observacao': observacao},
      );
      return Documento.fromJson(res.data?['data'] as Map<String, dynamic>);
    } catch (e) {
      throw mapDioError(e);
    }
  }
}
