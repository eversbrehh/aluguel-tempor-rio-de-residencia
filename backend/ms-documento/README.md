# MS Documento

Microsserviço de documentos do comodato — REST + Supabase Storage + consumidor de eventos do RabbitMQ.

## Stack
- Node.js 20+, TypeScript, Express, Multer
- Supabase (PostgreSQL + Storage) via `@supabase/supabase-js`
- RabbitMQ (`amqplib`) — produz e consome eventos
- Outbox Pattern (tabela própria + worker)

## Eventos
- **Consome** (fila `documentos.eventos`):
  - `associacao.criada` → cria solicitações padrão (RG, comprovante de renda, contrato)
  - `associacao.encerrada` (informativo)
- **Produz** (no exchange `lamd.events`):
  - `documento.solicitado`
  - `documento.enviado`
  - `documento.aprovado`
  - `documento.rejeitado`

## Como rodar (dev)

```powershell
# 1. RabbitMQ
docker compose up -d rabbitmq

# 2. SQL no Supabase (uma vez): cole db/documentos.sql no SQL Editor.
# 3. Bucket de Storage: em Storage > New bucket, criar "documentos" PRIVADO.

# 4. Env
copy .env.example .env
# editar SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RABBITMQ_URL

# 5. Dependências e execução
npm install
npm run dev
```

Health check: `GET http://localhost:3003/health`

## Endpoints (`/api/v1/documentos`)

Todos exigem `Authorization: Bearer <accessToken Supabase>`.

| Método | Rota | Quem | Descrição |
|---|---|---|---|
| `POST` | `/` | proprietário | Solicita documento (`associacaoId`, `tipo`, `titulo`) |
| `GET`  | `/?associacaoId=` | ambos | Lista; sem filtro, todos visíveis ao usuário |
| `POST` | `/:id/upload` (multipart `file`) | comodatário | Envia arquivo → Storage |
| `GET`  | `/:id/download` | ambos | Gera signed URL temporário |
| `PATCH`| `/:id/aprovar` | proprietário | Marca como aprovado |
| `PATCH`| `/:id/rejeitar` (body opcional `observacao`) | proprietário | Marca como rejeitado |
