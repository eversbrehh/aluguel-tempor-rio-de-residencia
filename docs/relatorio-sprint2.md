# Relatório — Sprint 2: Integração Assíncrona com MOM

**Disciplina:** Arquitetura de Sistemas Distribuídos — PUC Minas
**Sistema:** LAMD — Aluguel Temporário de Residência

## 1. Escolha do MOM

Foi adotado o **RabbitMQ 3.13** como _Message-Oriented Middleware_ (MOM), pelas seguintes razões:

- **Modelo AMQP 0.9.1** maduro, com suporte nativo a _exchanges_, _queues_, _bindings_ e _dead-lettering_.
- **Topic exchanges** permitem _routing key_ baseada em padrão (`associacao.*`), facilitando o fan-out seletivo entre os microsserviços.
- Ferramentas de operação (UI de _management_) e _client_ Node.js (`amqplib`) consolidados.
- Execução local trivial via Docker — alinhada ao requisito de _setup_ reprodutível.

## 2. Padrão Outbox

Para garantir **atomicidade** entre a mudança de estado do agregado (ex.: associação criada) e a publicação do evento correspondente, adotou-se o **Outbox Pattern** [1][2]:

1. _Triggers_ PostgreSQL `AFTER INSERT/UPDATE` em `imoveis` e `associacoes` inserem o evento na tabela `outbox_events` na **mesma transação** da mudança de negócio.
2. Um _worker_ no monolito (`OutboxWorker`) faz _polling_ com `SELECT ... FOR UPDATE SKIP LOCKED` (função `claim_outbox_batch`), publica no RabbitMQ e marca `published`.
3. Em falha de publicação, o registro permanece em `pending` para retry; após `OUTBOX_MAX_ATTEMPTS` tentativas é marcado como `failed`.

Essa abordagem evita o problema clássico do _dual write_ entre BD e _broker_, em troca de _at-least-once delivery_ — gerenciada pela idempotência no consumidor.

## 3. Topologia AMQP

- **Exchange principal:** `lamd.events` (topic, durable)
- **DLX:** `lamd.events.dlx` + **DLQ** `lamd.events.dlq`
- **Filas (todas com `x-dead-letter-exchange`):**
  - `notificacoes.eventos` ← `associacao.*`, `imovel.criado`
  - `tarefas.eventos` ← `associacao.*` (consumidor: Sprint 3)
  - `chat.eventos` ← `associacao.*` (Sprint 3)
  - `documentos.eventos` ← `associacao.criada` (Sprint 3)

Cada evento é publicado com `persistent: true` e _routing key_ = `eventType`.

## 4. Idempotência no Consumidor

O MS Notificações mantém a tabela `processed_events` (PK = `event_id`). Antes de processar uma mensagem, verifica-se se o `eventId` já foi gravado; em caso afirmativo, faz-se **ack** sem efeito colateral. Após o processamento bem-sucedido, o `eventId` é registrado.

Em redeliveries (ex.: ack perdido por crash), o consumidor reconhece o evento como já processado, garantindo idempotência funcional [3].

## 5. Limitações e Trabalhos Futuros

- **Polling do Outbox:** o intervalo (`OUTBOX_POLL_INTERVAL_MS=1000`) introduz latência. Para latências sub-segundo, pode-se evoluir para _Change Data Capture_ (CDC) sobre o WAL do Postgres.
- **Reentrega da DLQ:** atualmente é manual (via UI). Um _replay worker_ está previsto para uma sprint posterior.
- **Escalabilidade do worker:** o uso de `FOR UPDATE SKIP LOCKED` já suporta múltiplos workers em paralelo — habilitando _scale-out_ horizontal.
- **MS Tarefa/Chat/Documento:** entregues como esqueletos com bindings já declarados; consumirão os eventos na Sprint 3.

## Referências

1. **Hohpe, G.; Woolf, B.** _Enterprise Integration Patterns_. Addison-Wesley, 2003.
2. **Richardson, C.** _Microservices Patterns_. Manning, 2018. (Capítulos sobre _Saga_ e _Transactional Outbox_.)
3. **Coulouris, G.; Dollimore, J.; Kindberg, T.; Blair, G.** _Distributed Systems: Concepts and Design_, 5ª ed. Addison-Wesley, 2011.
