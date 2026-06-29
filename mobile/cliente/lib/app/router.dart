import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/cadastro_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/documentos/presentation/documentos_tab.dart';
import '../features/imoveis/presentation/imovel_detalhe_page.dart';
import '../features/notificacoes/presentation/notificacoes_page.dart';
import '../features/perfil/presentation/perfil_page.dart';
import '../features/shell/home_shell.dart';
import '../features/shell/meus_imoveis_page.dart';
import '../features/tarefas/presentation/tarefas_tab.dart';

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const cadastro = '/cadastro';
  static const home = '/';
  static const imoveis = '/imoveis';
  static const notificacoes = '/notificacoes';
  static const perfil = '/perfil';
  static String imovelDetalhe(String id) => '/imoveis/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Importante: NÃO usamos `ref.watch(authControllerProvider)` aqui — isso
  // recriaria o GoRouter inteiro a cada login/logout, perdendo histórico
  // de navegação e podendo deixar o MaterialApp.router preso na instância
  // antiga. Em vez disso, escutamos o auth via `refreshListenable` e lemos
  // o estado atual dentro do `redirect`.
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn =
          ref.read(authControllerProvider).value?.isAuthenticated ?? false;
      final loggingIn =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.cadastro;
      if (!loggedIn) return loggingIn ? null : AppRoutes.login;
      if (loggingIn) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: AppRoutes.cadastro,
        builder: (_, _) => const CadastroPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const MeusImoveisPage(),
          ),
          GoRoute(
            path: AppRoutes.notificacoes,
            builder: (_, _) => const NotificacoesPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/imoveis/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ImovelDetalhePage(imovelId: id);
        },
        routes: [
          GoRoute(
            path: 'tarefas',
            builder: (context, state) => TarefasTab(
              associacaoId: state.uri.queryParameters['associacaoId'] ?? '',
              imovelId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'documentos',
            builder: (context, state) => DocumentosTab(
              associacaoId: state.uri.queryParameters['associacaoId'] ?? '',
            ),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.perfil, builder: (_, _) => const PerfilPage()),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _sub = _ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
