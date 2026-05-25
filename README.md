# Sistema para Aluguel Temporário de Residência (LAMD)

Projeto Integrador da disciplina **Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas** — PUC Minas, 5º período (1º/2026).

Aluna: **Brenda Evers**

## Visão geral

Sistema distribuído orientado a eventos para gerenciamento de aluguéis temporários compartilhados (moradias por comodato). Conta com dois aplicativos móveis em Flutter (cliente e prestador), backend REST em Node.js, middleware orientado a mensagens (RabbitMQ), cache em Redis e persistência polyglot (Supabase + MongoDB).

A documentação completa da proposta está em [Documentação LAMD.md](Documentação%20LAMD.md) e as orientações da disciplina em [Projeto LAMD.md](Projeto%20LAMD.md).

## Estrutura do monorepo

```
/
├── backend/
│   ├── monolito/         # Backend REST + Outbox Publisher (Sprints 1 e 2)
│   ├── ms-notificacoes/  # Microsserviço consumidor de eventos (Sprint 2)
│   ├── ms-tarefa/        # Esqueleto — Sprint 3
│   ├── ms-chat/          # Esqueleto — Sprint 3
│   └── ms-documento/     # Esqueleto — Sprint 3
├── mobile/
│   ├── cliente/         # App Flutter do comodatário (Sprint 3)
│   └── prestador/       # App Flutter do proprietário (Sprint 4)
├── docs/
│   ├── events.md
│   ├── relatorio-sprint2.md
│   ├── arquitetura.png
│   └── postman-collection.json
└── docker-compose.yml    # RabbitMQ local
```

## Sprints

| Sprint | Foco | Status |
|---|---|---|
| 1 | Backend REST + arquitetura | concluída |
| 2 | Integração com MOM (RabbitMQ) | concluída |
| 3 | App Flutter Cliente | — |
| 4 | App Flutter Prestador + entrega final | — |

## Como subir a infraestrutura local

```powershell
# 1. Subir RabbitMQ (raiz do repositório)
copy .env.example .env   # opcional — define credenciais do broker
docker compose up -d rabbitmq

# UI de management: http://localhost:15672  (user/pass do .env)
```

## Como executar

Cada módulo possui o próprio `README.md` com instruções:

- Backend monolito: [backend/monolito/README.md](backend/monolito/README.md)
- MS Notificações: [backend/ms-notificacoes/README.md](backend/ms-notificacoes/README.md)
