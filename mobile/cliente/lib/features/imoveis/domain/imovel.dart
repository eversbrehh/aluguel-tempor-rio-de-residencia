/// Domínio: Imóvel exibido no app.
class Imovel {
  const Imovel({
    required this.id,
    required this.proprietarioId,
    required this.titulo,
    required this.endereco,
    this.descricao,
    this.valorAluguel,
  });

  final String id;
  final String proprietarioId;
  final String titulo;
  final String endereco;
  final String? descricao;
  final double? valorAluguel;

  factory Imovel.fromJson(Map<String, dynamic> j) => Imovel(
    id: j['id'] as String,
    proprietarioId: j['proprietarioId'] as String,
    titulo: j['titulo'] as String,
    endereco: j['endereco'] as String,
    descricao: j['descricao'] as String?,
    valorAluguel: (j['valorAluguel'] as num?)?.toDouble(),
  );
}

/// Associação ativa (entre comodatário e imóvel).
class Associacao {
  const Associacao({
    required this.id,
    required this.imovelId,
    required this.comodatarioId,
    required this.dataInicio,
    this.dataFim,
    this.comodatarioNome,
  });

  final String id;
  final String imovelId;
  final String comodatarioId;
  final String dataInicio;
  final String? dataFim;
  final String? comodatarioNome;

  factory Associacao.fromJson(Map<String, dynamic> j) => Associacao(
    id: j['id'] as String,
    imovelId: j['imovelId'] as String,
    comodatarioId: j['comodatarioId'] as String,
    dataInicio: j['dataInicio'] as String,
    dataFim: j['dataFim'] as String?,
    comodatarioNome: j['comodatarioNome'] as String?,
  );
}
