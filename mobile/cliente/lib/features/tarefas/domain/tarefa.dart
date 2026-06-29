class Tarefa {
  const Tarefa({
    required this.id,
    required this.associacaoId,
    required this.imovelId,
    required this.proprietarioId,
    required this.comodatarioId,
    required this.titulo,
    this.descricao,
    required this.recorrencia,
    this.prazo,
    required this.status,
    required this.createdAt,
    this.concluidaEm,
  });

  final String id;
  final String associacaoId;
  final String imovelId;
  final String proprietarioId;
  final String comodatarioId;
  final String titulo;
  final String? descricao;
  final String recorrencia; // unica/diaria/semanal/mensal
  final String? prazo;
  final String status; // pendente/concluida/arquivada
  final DateTime createdAt;
  final DateTime? concluidaEm;

  bool get isPendente => status == 'pendente';

  factory Tarefa.fromJson(Map<String, dynamic> j) => Tarefa(
    id: j['id'] as String,
    associacaoId: j['associacaoId'] as String,
    imovelId: j['imovelId'] as String,
    proprietarioId: j['proprietarioId'] as String,
    comodatarioId: j['comodatarioId'] as String,
    titulo: j['titulo'] as String,
    descricao: j['descricao'] as String?,
    recorrencia: (j['recorrencia'] as String?) ?? 'unica',
    prazo: j['prazo'] as String?,
    status: (j['status'] as String?) ?? 'pendente',
    createdAt:
        DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
    concluidaEm: j['concluidaEm'] == null
        ? null
        : DateTime.tryParse(j['concluidaEm'] as String),
  );
}
