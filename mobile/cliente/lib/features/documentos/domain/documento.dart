class Documento {
  const Documento({
    required this.id,
    required this.associacaoId,
    required this.imovelId,
    required this.proprietarioId,
    required this.comodatarioId,
    required this.tipo,
    required this.titulo,
    required this.status,
    this.storagePath,
    this.fileName,
    this.observacao,
    required this.createdAt,
  });

  final String id;
  final String associacaoId;
  final String imovelId;
  final String proprietarioId;
  final String comodatarioId;
  final String tipo;
  final String titulo;
  final String status; // solicitado/enviado/aprovado/rejeitado
  final String? storagePath;
  final String? fileName;
  final String? observacao;
  final DateTime createdAt;

  bool get podeEnviar => status == 'solicitado' || status == 'rejeitado';
  bool get podeBaixar => storagePath != null && storagePath!.isNotEmpty;

  factory Documento.fromJson(Map<String, dynamic> j) => Documento(
    id: j['id'] as String,
    associacaoId: j['associacaoId'] as String,
    imovelId: j['imovelId'] as String,
    proprietarioId: j['proprietarioId'] as String,
    comodatarioId: j['comodatarioId'] as String,
    tipo: j['tipo'] as String,
    titulo: j['titulo'] as String,
    status: (j['status'] as String?) ?? 'solicitado',
    storagePath: j['storagePath'] as String?,
    fileName: j['fileName'] as String?,
    observacao: j['observacao'] as String?,
    createdAt:
        DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
  );
}
