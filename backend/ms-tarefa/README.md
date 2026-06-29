# MS Tarefa

Microsserviço de tarefas de manutenção do imóvel — REST + consumidor de eventos do RabbitMQ.

## Stack
- Node.js 20+, TypeScript, Express
- Supabase (PostgreSQL) via `@supabase/supabase-js`
- RabbitMQ (`amqplib`) — produz e consome eventos
- Outbox Pattern (tabela própria + worker)

## Eventos
- **Consome** (fila `tarefas.eventos`):
  - `associacao.criada` (acknowledge informativo)
  - `associacao.encerrada` → arquiva tarefas pendentes daquela associação
- **Produz** (no exchange `lamd.events`):
  - `tarefa.criada`
  - `tarefa.concluida`

## Como rodar (dev)

```powershell
# 1. RabbitMQ na raiz do repo
docker compose up -d rabbitmq

# 2. SQL do MS no Supabase (uma vez):
#    cole db/tarefas.sql no SQL Editor.

# 3. Env
copy .env.example .env
# editar SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RABBITMQ_URL

# 4. Dependências e execução
npm install
npm run dev
```

Health check: `GET http://localhost:3002/health`

## Endpoints (`/api/v1/tarefas`)

Todos exigem `Authorization: Bearer <accessToken Supabase>`.

| Método | Rota | Quem | Descrição |
|---|---|---|---|
| `POST` | `/` | proprietário | Cria tarefa (`associacaoId`, `titulo`, `descricao?`, `recorrencia?`, `prazo?`) |
| `GET`  | `/?associacaoId=` ou `?imovelId=` | ambos | Lista tarefas; sem filtro retorna todas visíveis pelo usuário |
| `PATCH`| `/:id/concluir` | comodatário | Marca tarefa como concluída |
