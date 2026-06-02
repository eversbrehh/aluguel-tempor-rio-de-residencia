# Relatório — Sprint 2: Integração Assíncrona com MOM

**Disciplina:** Arquitetura de Sistemas Distribuídos — PUC Minas
**Sistema:** LAMD — Aluguel Temporário de Residência

## 1. Escolha do MOM

Foi adotado o **RabbitMQ 3.13** como _Message-Oriented Middleware_ (MOM), pelas seguintes razões:

- Ferramenta gratuita para o presente trabalho;
- Suporta a criação de mais nós para trabalharem simultaneamente, permitindo o estudo e aplicação de escalabilidade horizontal;
- Versatilidade de uso: a ferramenta dispensa treinamentos devido a fácil compreensão das funcionalidades.

## 2. Topologia AMQP

- **Exchange principal:** `lamd.events` (topic, durable)
- **DLX:** `lamd.events.dlx` + **DLQ** `lamd.events.dlq`
- **Filas (todas com `x-dead-letter-exchange`):**
  - `notificacoes.eventos` ← `associacao.*`, `imovel.criado`
  - `tarefas.eventos` ← `associacao.*` (consumidor: Sprint 3)
  - `chat.eventos` ← `associacao.*` (Sprint 3)
  - `documentos.eventos` ← `associacao.criada` (Sprint 3)

Cada evento é publicado com `persistent: true` e _routing key_ = `eventType`.

## 3. Idempotência no Consumidor

O MS Notificações mantém a tabela `processed_events` (PK = `event_id`). Antes de processar uma mensagem, verifica-se se o `eventId` já foi gravado; em caso afirmativo, faz-se **ack** sem efeito colateral. Após o processamento bem-sucedido, o `eventId` é registrado.

Em redeliveries (ex.: ack perdido por crash), o consumidor reconhece o evento como já processado, garantindo idempotência funcional [3].

## 4. Observações do sistema com mensageria

A mensageria atua como um correio que envia a mensagem do remetente para o destinatário. No presente contexto, o remetente atua como o Monolito, e o destinatário atua como o MS Notificação. A dinâmica entre estes dois consiste na responsabilidade do monolito enviar a mensagem contendo a alteração que foi efetuada para que o microsserviço de notificação, servindo como insumo para que este possa aplicar as regras de negócio implementadas.

O desacoplamento entre estas duas aplicações evita que uma perda geral no sistema ocorra caso uma das instâncias pare de funcionar — o que pode ser observado ao executar o produtor(monolito) sem que o consumidor(MS Notificações) estivesse ativo. As mensagens permaneceram pendentes para o consumo durante o estado offline deste e, quando voltou a ficar ativo, consumiu as mensagens pendentes.