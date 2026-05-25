# MS Notificações

Microsserviço que consome eventos de domínio do RabbitMQ e persiste notificações na tabela `notificacoes` do Supabase.

## Eventos consumidos
Fila: `notificacoes.eventos`

- `imovel.criado` — notifica o proprietário.
- `associacao.criada` — notifica proprietário e comodatário.
- `associacao.encerrada` — notifica proprietário e comodatário.

## Características
- **Idempotência**: tabela `processed_events` (PK = `event_id`) impede reprocessamento.
- **Prefetch** configurável via `RABBITMQ_PREFETCH`.
- **Dead-letter**: mensagens com envelope inválido, sem handler ou que lançam exceção vão para `lamd.events.dlq` via DLX.

## Como rodar (dev)

```powershell
# 1. Subir RabbitMQ (na raiz do repo)
docker compose up -d rabbitmq

# 2. Executar o schema (uma vez)
#    Cole o conteúdo de db/notificacoes.sql no SQL Editor do Supabase.

# 3. Variáveis de ambiente
copy .env.example .env
# edite .env com SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RABBITMQ_URL

# 4. Dependências e execução
npm install
npm run dev
```
