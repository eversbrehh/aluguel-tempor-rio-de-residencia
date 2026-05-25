# Eventos de Domínio — Sprint 2

Este documento descreve o **contrato de eventos** publicado pelo Monolito LAMD no RabbitMQ e consumido pelos microsserviços.

## Envelope (JSON)

Todos os eventos seguem o mesmo envelope:

```json
{
  "eventId": "uuid v4",
  "eventType": "imovel.criado",
  "occurredAt": "2025-01-15T12:34:56.789Z",
  "source": "monolito",
  "version": 1,
  "payload": { /* específico por evento */ }
}
```

- **eventId**: UUID único — usado para idempotência pelos consumidores.
- **eventType**: nome do evento (também usado como _routing key_).
- **occurredAt**: timestamp ISO-8601 em UTC.
- **source**: identificador do produtor.
- **version**: versão do contrato do payload.
- **payload**: dados específicos do evento.

## Topologia AMQP

- **Exchange principal:** `lamd.events` (topic, durable)
- **Dead-Letter Exchange:** `lamd.events.dlx` (topic, durable)
- **DLQ:** `lamd.events.dlq` (durable, bind `#`)

```mermaid
flowchart LR
  Monolito((Monolito + Outbox Worker)) -- publish --> EX[lamd.events<br/>topic]
  EX -- associacao.* / imovel.criado --> QN[notificacoes.eventos]
  EX -- associacao.* --> QT[tarefas.eventos]
  EX -- associacao.* --> QC[chat.eventos]
  EX -- associacao.criada --> QD[documentos.eventos]
  QN -- nack/erro --> DLX[lamd.events.dlx]
  QT -- nack/erro --> DLX
  QC -- nack/erro --> DLX
  QD -- nack/erro --> DLX
  DLX -- "#" --> DLQ[lamd.events.dlq]
  QN --> MN[MS Notificações]
  QT -.-> MT[MS Tarefa - Sprint 3]
  QC -.-> MC[MS Chat - Sprint 3]
  QD -.-> MD[MS Documento - Sprint 3]
```

## Catálogo de Eventos

### `imovel.criado`
Publicado quando um imóvel é cadastrado.

| Campo            | Tipo           | Descrição                       |
|------------------|----------------|---------------------------------|
| `imovelId`       | uuid           | Id do imóvel                    |
| `proprietarioId` | uuid           | Profile do proprietário         |
| `titulo`         | string         | Título do imóvel                |
| `endereco`       | string         | Endereço                        |
| `valorAluguel`   | number \| null | Valor do aluguel (opcional)     |
| `criadoEm`       | timestamp ISO  | Quando foi inserido             |

**Bindings:** `notificacoes.eventos`.

---

### `associacao.criada`
Publicado ao criar uma associação imóvel↔comodatário.

| Campo            | Tipo           | Descrição                  |
|------------------|----------------|----------------------------|
| `associacaoId`   | uuid           | Id da associação           |
| `imovelId`       | uuid           | Id do imóvel               |
| `comodatarioId`  | uuid           | Profile do comodatário     |
| `proprietarioId` | uuid           | Profile do proprietário    |
| `dataInicio`     | date YYYY-MM-DD| Início do comodato         |
| `dataFim`        | date \| null   | Fim previsto (opcional)    |
| `criadoEm`       | timestamp ISO  | Quando foi inserido        |

**Bindings:** `notificacoes.eventos`, `tarefas.eventos`, `chat.eventos`, `documentos.eventos`.

---

### `associacao.encerrada`
Publicado quando uma associação ativa é encerrada.

| Campo            | Tipo           | Descrição                  |
|------------------|----------------|----------------------------|
| `associacaoId`   | uuid           | Id da associação           |
| `imovelId`       | uuid           | Id do imóvel               |
| `comodatarioId`  | uuid           | Profile do comodatário     |
| `proprietarioId` | uuid           | Profile do proprietário    |
| `dataFim`        | date \| null   | Data efetiva de encerramento|
| `encerradaEm`    | timestamp ISO  | `now()` no instante do update|

**Bindings:** `notificacoes.eventos`, `tarefas.eventos`, `chat.eventos`.

## Garantias

- **Atomicidade entre estado e evento:** uso do _Outbox Pattern_. Triggers do Postgres gravam o evento na tabela `outbox_events` na mesma transação da mudança de estado. Um worker no monolito (`OutboxWorker`) faz polling com `SELECT ... FOR UPDATE SKIP LOCKED` e publica no RabbitMQ.
- **At-least-once delivery:** mensagens publicadas com `persistent: true`. Em caso de crash entre publicação e `mark_outbox_published`, a mensagem pode ser republicada — daí a importância da idempotência no consumidor.
- **Idempotência no consumidor:** tabela `processed_events` (PK = `event_id`) impede efeitos colaterais duplicados.
- **Retry e DLQ:** mensagens com envelope inválido, sem handler ou que lançam exceção vão para `lamd.events.dlq` via DLX.
