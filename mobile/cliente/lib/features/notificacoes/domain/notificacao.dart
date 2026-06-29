class Notificacao {
  const Notificacao({
    required this.id,
    required this.tipo,
    required this.payload,
    required this.lida,
    required this.criadaEm,
  });

  final String id;
  final String tipo;
  final Map<String, dynamic> payload;
  final bool lida;
  final DateTime criadaEm;

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
    id: j['id'] as String,
    tipo: j['tipo'] as String,
    payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    lida: (j['lida'] as bool?) ?? false,
    criadaEm:
        DateTime.tryParse((j['criadaEm'] as String?) ?? '') ?? DateTime.now(),
  );

  String get titulo {
    final t = payload['titulo'] ?? payload['mensagem'];
    if (t is String) return t;
    return _legivel(tipo);
  }

  String get mensagem {
    final m = payload['mensagem'] ?? payload['descricao'];
    if (m is String) return m;
    return '';
  }

  static String _legivel(String tipo) {
    switch (tipo) {
      case 'imovel.criado':
        return 'Novo imóvel cadastrado';
      case 'associacao.criada':
        return 'Você foi associado a um imóvel';
      case 'associacao.encerrada':
        return 'Sua associação foi encerrada';
      case 'tarefa.criada':
        return 'Nova tarefa atribuída';
      case 'tarefa.concluida':
        return 'Tarefa concluída';
      case 'documento.solicitado':
        return 'Documento solicitado';
      case 'documento.enviado':
        return 'Documento enviado';
      case 'documento.aprovado':
        return 'Documento aprovado';
      case 'documento.rejeitado':
        return 'Documento rejeitado';
      default:
        return tipo;
    }
  }
}

class NotificacoesListResult {
  const NotificacoesListResult({required this.itens, required this.naoLidas});
  final List<Notificacao> itens;
  final int naoLidas;
}
