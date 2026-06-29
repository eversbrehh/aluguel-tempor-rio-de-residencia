# LAMD — App Cliente (Flutter)

Aplicativo móvel para **proprietários** e **comodatários** da plataforma LAMD
(Aluguel Temporário de Residência).

> Projeto desenvolvido para a disciplina de **Laboratório de
> Desenvolvimento de Software (ESW501)** — PUC Minas. Autora: **Brenda Evers
> Quinhones Cavalcante**.

## Visão geral

- Login / cadastro com Supabase (via monolito).
- Lista de imóveis vinculados ao usuário (papel proprietário vê seus imóveis;
  comodatário vê o imóvel atualmente associado).
- Detalhe do imóvel com abas:
  - **Resumo** — endereço, status do contrato e parte associada.
  - **Tarefas** — checklist de manutenção criado pelo proprietário,
    concluído pelo comodatário.
  - **Documentos** — solicitação, upload, download, aprovação e rejeição
    do contrato/comprovantes.
- **Notificações em tempo real** via WebSocket (`socket.io`) com badge no
  bottom navigation e atualização automática das listas relevantes
  (`tarefa.criada`, `documento.aprovado`, etc.) sem o usuário precisar
  recarregar a tela.

## Pré-requisitos

- **Flutter SDK** 3.22+ (recomendado 3.44.x) — `flutter --version`
- **Dart SDK** 3.4+
- Backend rodando localmente (`docker compose up -d` + `npm run dev` em cada
  serviço — ver READMEs do diretório `backend/`).

## Instalação

```bash
cd mobile/cliente
flutter pub get
```

## Execução

O app lê quatro `dart-define` para apontar para o backend. Os valores padrão
assumem **emulador Android** no host (10.0.2.2).

### Emulador Android (default)

```bash
flutter run
```

Equivale a:

```bash
flutter run \
  --dart-define=MONOLITO_BASE_URL=http://10.0.2.2:3000/api/v1 \
  --dart-define=NOTIFICACOES_BASE_URL=http://10.0.2.2:3001/api/v1 \
  --dart-define=NOTIFICACOES_WS_URL=http://10.0.2.2:3001 \
  --dart-define=TAREFA_BASE_URL=http://10.0.2.2:3002/api/v1 \
  --dart-define=DOCUMENTO_BASE_URL=http://10.0.2.2:3003/api/v1
```

### Dispositivo físico ou web

Troque `10.0.2.2` pelo IP da máquina onde o backend está rodando (ex.
`192.168.0.10`):

```bash
flutter run -d chrome \
  --dart-define=MONOLITO_BASE_URL=http://192.168.0.10:3000/api/v1 \
  --dart-define=NOTIFICACOES_BASE_URL=http://192.168.0.10:3001/api/v1 \
  --dart-define=NOTIFICACOES_WS_URL=http://192.168.0.10:3001 \
  --dart-define=TAREFA_BASE_URL=http://192.168.0.10:3002/api/v1 \
  --dart-define=DOCUMENTO_BASE_URL=http://192.168.0.10:3003/api/v1
```

> **Atenção:** para web é necessário configurar **CORS** no backend para
> permitir o origin `http://localhost:<porta>`.

### Smoke test

```bash
flutter test
```

Roda `test/widget_test.dart`, que monta o app e verifica o `MaterialApp`.

### Análise estática

```bash
flutter analyze --no-fatal-infos
```

Hoje o projeto está com **0 erros / 0 warnings** e ~10 *infos*
estilísticas (uso de `__`, `if (x != null) 'k': x` etc.), preservadas para
manter clareza do código.

## Arquitetura

Adota **Clean Architecture** organizada por *feature*:

```
lib/
├── main.dart
├── app/                     # bootstrap, DI, tema, rotas
│   ├── providers.dart       # secureStorage, dio clients, socket, handler 401
│   ├── router.dart          # go_router + guarda baseada em AuthController
│   └── theme.dart
├── core/                    # cross-cutting (sem dependência de feature)
│   ├── env/                 # AppEnv (dart-define)
│   ├── errors/              # AppFailure sealed
│   ├── http/                # buildDio + AuthInterceptor + mapDioError
│   ├── realtime/            # NotificacoesSocket (socket.io)
│   ├── storage/             # TokenStorage (flutter_secure_storage)
│   └── widgets/             # SectionTitle, EmptyState, StatusChip, ErrorView
└── features/
    ├── auth/{domain,data,presentation}
    ├── imoveis/{domain,data,presentation}
    ├── tarefas/{domain,data,presentation}
    ├── documentos/{domain,data,presentation}
    ├── notificacoes/{domain,data,presentation}
    └── shell/                # HomeShell (bottom nav) + MeusImoveisPage
```

Cada feature segue a camada:

| Camada           | Responsabilidade                                                      |
| ---------------- | --------------------------------------------------------------------- |
| **domain**       | *Entities* puras (sem Flutter) e contratos de dados.                  |
| **data**         | *Repositories* que falam HTTP via `dio` e mapeiam para entidades.     |
| **presentation** | *Controllers* (Riverpod `Notifier`/`FutureProvider.family`) + telas.  |

### Stack

| Pacote                    | Uso                                                |
| ------------------------- | -------------------------------------------------- |
| `flutter_riverpod 3.x`    | Injeção de dependência + estado reativo            |
| `go_router`               | Navegação declarativa com guarda de autenticação   |
| `dio`                     | HTTP + interceptors + `FormData` para uploads      |
| `flutter_secure_storage`  | Persistência do access token no Keystore           |
| `socket_io_client`        | WebSocket com `ms-notificacoes` (sala `user:<id>`) |
| `file_picker`             | Seleção de arquivos para upload                    |
| `intl`                    | Datas e moedas em `pt_BR`                          |
| `flutter_localizations`   | Localização Material em português                  |

## Mapeamento dos 5 critérios de avaliação

> Os números correspondem aos critérios da disciplina (sprint da entrega
> mobile).

### 1. Funcionalidade do app (fluxo completo executável)

Fluxo end-to-end implementado:

- **Cadastro** → [features/auth/presentation/cadastro_page.dart](lib/features/auth/presentation/cadastro_page.dart) — escolhe papel (comodatário/proprietário), valida senha mínima de 8 chars.
- **Login** → [features/auth/presentation/login_page.dart](lib/features/auth/presentation/login_page.dart) — após sucesso busca `/auth/me` e conecta o socket.
- **Lista de imóveis** → [features/shell/meus_imoveis_page.dart](lib/features/shell/meus_imoveis_page.dart) — pull-to-refresh, navega para detalhe.
- **Detalhe + abas** → [features/imoveis/presentation/imovel_detalhe_page.dart](lib/features/imoveis/presentation/imovel_detalhe_page.dart) — escolhe associação ativa do usuário e injeta nas abas filhas.
- **Tarefas** → [features/tarefas/presentation/tarefas_tab.dart](lib/features/tarefas/presentation/tarefas_tab.dart) — proprietário cria via bottom sheet; comodatário marca como concluída.
- **Documentos** → [features/documentos/presentation/documentos_tab.dart](lib/features/documentos/presentation/documentos_tab.dart) — proprietário solicita e aprova/rejeita; comodatário envia arquivo via `FilePicker` + baixa link assinado.
- **Notificações** → [features/notificacoes/presentation/notificacoes_page.dart](lib/features/notificacoes/presentation/notificacoes_page.dart) — lista paginada, "marcar todas como lidas", badge no bottom nav.
- **Logout** → `Drawer` em [features/shell/home_shell.dart](lib/features/shell/home_shell.dart) limpa o token e desconecta o socket.

### 2. Integração correta com o backend REST

- 4 clientes `dio` distintos (monolito, notificações, tarefas, documentos),
  cada um com `baseUrl` e `AuthInterceptor` próprios — definidos em
  [app/providers.dart](lib/app/providers.dart).
- Token injetado automaticamente via [core/http/auth_interceptor.dart](lib/core/http/auth_interceptor.dart);
  401 dispara o `unauthorizedHandlerProvider` (logout forçado).
- Erros HTTP traduzidos em `AppFailure` (`Network`/`Unauthorized`/`Validation`/`Server`)
  por [core/errors/failures.dart](lib/core/errors/failures.dart) — UI mostra mensagem amigável via `ErrorView`.
- Repositórios consomem os endpoints reais do backend:
  - `POST /auth/login`, `POST /auth/register`, `GET /auth/me`
  - `GET /imoveis`, `GET /imoveis/:id`, `GET /imoveis/:id/associacoes`
  - `GET/POST /tarefas`, `PATCH /tarefas/:id/concluir`
  - `GET/POST /documentos`, `POST /documentos/:id/upload` (multipart),
    `GET /documentos/:id/download`, `PATCH /documentos/:id/aprovar|rejeitar`
  - `GET /notificacoes`, `PATCH /notificacoes/marcar-todas-lidas`,
    `PATCH /notificacoes/:id/lida`

### 3. Atualização assíncrona de estado implementada

- **WebSocket único** em [core/realtime/notificacoes_socket.dart](lib/core/realtime/notificacoes_socket.dart),
  compartilhado via `notificacoesSocketProvider` — conecta após o login,
  desconecta no logout (em [features/auth/presentation/auth_controller.dart](lib/features/auth/presentation/auth_controller.dart)).
- O servidor coloca o cliente na sala `user:<id>` e emite
  `notificacao:nova` quando um novo evento de domínio chega.
- Cada controller relevante **assina o stream** e invalida o próprio
  estado quando recebe um evento do tipo certo, sem precisar de pull
  manual:
  - [features/notificacoes/presentation/notificacoes_controller.dart](lib/features/notificacoes/presentation/notificacoes_controller.dart) — refresh da lista + badge.
  - [features/tarefas/presentation/tarefas_controller.dart](lib/features/tarefas/presentation/tarefas_controller.dart) — `ref.invalidateSelf()` em eventos `tarefa.*`.
  - [features/documentos/presentation/documentos_controller.dart](lib/features/documentos/presentation/documentos_controller.dart) — idem em `documento.*`.
- O badge de notificações não-lidas em [features/shell/home_shell.dart](lib/features/shell/home_shell.dart)
  é alimentado pelo mesmo controller — propaga em tempo real.

### 4. Organização do código Flutter (Clean Architecture)

- Separação **feature-first** com camadas `domain`/`data`/`presentation` em
  cada uma — fronteiras claras e dependências apontando para dentro
  (presentation depende de data, data depende de domain).
- Camada `core/` agrupa o que é transversal (HTTP, WS, storage, erros,
  widgets compartilhados) sem importar nenhuma feature.
- **DI 100% via Riverpod** em [app/providers.dart](lib/app/providers.dart) — fácil testar
  trocando providers em `ProviderScope(overrides: [...])`.
- Repositórios são puros e injetáveis (recebem `Dio` no construtor).
- Modelos de domínio em arquivos isolados (`auth_user.dart`,
  `imovel.dart`, `tarefa.dart`, etc.) sem dependência de Flutter.

### 5. Qualidade da interface (usabilidade e clareza)

- **Material 3** com tema customizado verde (`Color(0xFF2E7D5B)`) em
  [app/theme.dart](lib/app/theme.dart).
- **NavigationBar** (M3) com **Badge** dinâmico de não-lidas em
  [features/shell/home_shell.dart](lib/features/shell/home_shell.dart).
- **Pull-to-refresh** nas listas de imóveis, tarefas, documentos e
  notificações.
- **Estados** explícitos com `AsyncValue.when` →
  `AppLoading` / `ErrorView` (com botão "Tentar novamente") /
  `EmptyState` (com ícone e texto explicativo).
- **Locale `pt_BR`** com `flutter_localizations` e `initializeDateFormatting`
  em [main.dart](lib/main.dart) — datas no formato `dd/MM/yyyy`.
- **Chips de status** coloridos em tarefas/documentos
  (`StatusChip` em [core/widgets/common.dart](lib/core/widgets/common.dart)).
- Controles **contextuais por papel**: o proprietário vê FAB de "Nova
  tarefa"/"Solicitar documento" e botões de aprovar/rejeitar; o
  comodatário vê "Concluir" e "Enviar arquivo".
- **Bottom sheets** com formulários validados para criar tarefa e
  solicitar documento.

## Próximos passos sugeridos

- Implementar refresh-token (atualmente o app só guarda o `accessToken`).
- Push notifications nativas (FCM/APNs) além do WebSocket.
- Capturar foto direto da câmera para upload de documento.
- Testes de integração com `mocktail` + `flutter_test`.
