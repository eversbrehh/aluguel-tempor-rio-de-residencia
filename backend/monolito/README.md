# Monolito Modular — Sprints 1 & 2

Backend REST do sistema de aluguel temporário de residência (LAMD) + **publisher do Outbox Pattern** para RabbitMQ.

## Stack

- **Node.js 20+** + **TypeScript**
- **Express** (HTTP)
- **Supabase** (PostgreSQL + Auth + Storage) via `@supabase/supabase-js`
- **Zod** (validação de payloads)
- **Helmet + CORS** (segurança básica)

## Pré-requisitos

1. Node.js 20+ e npm
2. Conta no [Supabase](https://supabase.com) com um projeto criado
3. Executar **em ordem** no SQL Editor do Supabase:
   1. `db/schema.sql` (Sprint 1)
   2. `db/sprint2-outbox.sql` (Sprint 2 — outbox + triggers)
4. RabbitMQ rodando (via `docker compose up -d rabbitmq` na raiz do repo)

## Instalação

```bash
cd backend/monolito
npm install
cp .env.example .env
# Editar .env com as chaves do seu projeto Supabase
```

Variáveis obrigatórias em `.env`:

| Variável | Descrição |
|---|---|
| `SUPABASE_URL` | URL do projeto Supabase |
| `SUPABASE_ANON_KEY` | Chave pública (anon) |
| `SUPABASE_SERVICE_ROLE_KEY` | Chave privada (service role) — **não expor no frontend** |
| `PORT` | Porta HTTP (padrão: 3000) |
| `API_PREFIX` | Prefixo das rotas (padrão: `/api/v1`) |
| `CORS_ORIGIN` | Origens permitidas (padrão: `*` em dev) |
| `RABBITMQ_URL` | URL AMQP (ex.: `amqp://lamd:lamd123@localhost:5672`) |
| `RABBITMQ_EXCHANGE` | Exchange principal (padrão: `lamd.events`) |
| `OUTBOX_POLL_INTERVAL_MS` | Intervalo de polling do Outbox (padrão: 1000) |
| `OUTBOX_BATCH_SIZE` | Tamanho do lote (padrão: 20) |
| `OUTBOX_MAX_ATTEMPTS` | Tentativas antes de marcar `failed` (padrão: 5) |

## Execução

```bash
npm run dev      # desenvolvimento (hot reload)
npm run build    # compila para dist/
npm start        # roda dist/
npm run lint     # ESLint
npm run typecheck
```

Health check: `GET http://localhost:3000/health`

## Arquitetura (Clean Architecture)

```
src/
├── domain/              # Entidades + interfaces de repositório/serviço
│   ├── entities/
│   ├── repositories/
│   ├── services/
│   └── errors/
├── application/         # Casos de uso (regras de aplicação)
│   └── useCases/
├── infrastructure/      # Implementações concretas (Supabase)
│   ├── supabase/
│   ├── repositories/
│   └── auth/
├── interface/           # HTTP (Express): rotas, controllers, middlewares
│   ├── controllers/
│   ├── routes/
│   ├── middlewares/
│   ├── schemas/         # Zod DTOs
│   └── container.ts     # Wiring de dependências
├── config/
│   └── env.ts
├── app.ts               # Bootstrap do Express
└── server.ts            # Entry point
```

A direção de dependência aponta sempre para o domínio: `interface → application → domain` e `infrastructure → domain`.

## Endpoints

Todos retornam JSON no formato `{ "data": ... }` em sucesso e `{ "error": { "code", "message" } }` em falha.

### Autenticação (públicos)

#### `POST /api/v1/auth/register`
Cria um usuário (proprietário ou comodatário).

**Body:**
```json
{
  "email": "user@example.com",
  "password": "senha12345",
  "nome": "Maria",
  "tipo": "proprietario",
  "telefone": "+5531999990001"
}
```
**201:** `{ "data": { "userId": "uuid", "email": "..." } }`

#### `POST /api/v1/auth/login`
Autentica e retorna JWT do Supabase.

**Body:** `{ "email": "...", "password": "..." }`
**200:** `{ "data": { "accessToken": "...", "refreshToken": "...", "expiresIn": 3600, "userId": "uuid" } }`

### Imóveis (autenticados — header `Authorization: Bearer <accessToken>`)

#### `POST /api/v1/imoveis` (proprietário)
**Body:**
```json
{
  "titulo": "Apto Centro",
  "endereco": "Av. Afonso Pena, 1000",
  "descricao": "Mobiliado",
  "valorAluguel": 1800.00
}
```
**201:** `{ "data": <Imovel> }`

#### `GET /api/v1/imoveis/meus`
Lista imóveis do usuário autenticado:
- proprietário: seus imóveis cadastrados
- comodatário: imóveis com associação ativa

**200:** `{ "data": [<Imovel>, ...] }`

#### `GET /api/v1/imoveis/:id`
Detalhes (acesso restrito ao proprietário ou comodatário associado).
**200:** `{ "data": <Imovel> }`

#### `POST /api/v1/imoveis/:id/associacoes` (proprietário do imóvel)
Vincula um comodatário ao imóvel.

**Body:**
```json
{
  "comodatarioEmail": "comodatario@example.com",
  "dataInicio": "2026-05-20",
  "dataFim": "2026-12-20"
}
```
**201:** `{ "data": <Associacao> }`

#### `PATCH /api/v1/imoveis/:imovelId/associacoes/:associacaoId/encerrar` (proprietário)
Encerra uma associação ativa. Dispara o evento `associacao.encerrada`.

**Body (opcional):** `{ "dataFim": "2026-08-30" }`
**200:** `{ "data": <Associacao> }`

## Eventos (Sprint 2)

O monolito grava eventos na tabela `outbox_events` via _triggers_ e o `OutboxWorker` publica no RabbitMQ. Detalhes do contrato em [`../../docs/events.md`](../../docs/events.md).

| Evento | Disparado em |
|---|---|
| `imovel.criado` | `AFTER INSERT` em `imoveis` |
| `associacao.criada` | `AFTER INSERT` em `associacoes` |
| `associacao.encerrada` | `AFTER UPDATE` quando `status: ativa → encerrada` |

## Banco de dados

Schema completo (tabelas, triggers, RLS) em [`db/schema.sql`](db/schema.sql).

| Tabela | Descrição |
|---|---|
| `profiles` | 1:1 com `auth.users`; armazena nome, tipo e telefone |
| `imoveis` | Imóveis pertencentes a um proprietário |
| `associacoes` | Vínculo comodatário ↔ imóvel com período |

Trigger `handle_new_user()` popula `profiles` automaticamente ao registrar um usuário via Supabase Auth.

## Testes manuais

Importe a coleção [`../../docs/postman-collection.json`](../../docs/postman-collection.json) no Postman e execute na ordem sugerida (descrita na coleção).

## Erros possíveis

| Code | Status | Significado |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Payload inválido (zod) |
| `UNAUTHORIZED` | 401 | Token ausente/inválido |
| `FORBIDDEN` | 403 | Sem permissão para o recurso |
| `NOT_FOUND` | 404 | Recurso inexistente |
| `CONFLICT` | 409 | Estado conflitante (ex.: associação já ativa) |
| `INTERNAL_ERROR` | 500 | Erro inesperado |
