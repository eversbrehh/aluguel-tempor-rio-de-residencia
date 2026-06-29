import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../documentos/presentation/documentos_controller.dart';
import '../../imoveis/presentation/imovel_controller.dart';
import '../../notificacoes/presentation/notificacoes_controller.dart';
import '../../tarefas/presentation/tarefas_controller.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(monolitoClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  return AuthRepository(dio, storage);
});

class AuthState {
  const AuthState({this.user});
  final AuthUser? user;
  bool get isAuthenticated => user != null;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.currentUser();
    if (user != null) {
      // conecta socket sob demanda
      // ignore: unawaited_futures
      ref.read(notificacoesSocketProvider).connect();
    }
    return AuthState(user: user);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      _invalidateUserScopedProviders();
      // ignore: unawaited_futures
      ref.read(notificacoesSocketProvider).connect();
      state = AsyncData(AuthState(user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
    required String tipo,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(nome: nome, email: email, password: password, tipo: tipo);
      _invalidateUserScopedProviders();
      // ignore: unawaited_futures
      ref.read(notificacoesSocketProvider).connect();
      state = AsyncData(AuthState(user: user));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    // 1. Limpa o token persistido — qualquer rebuild a partir daqui não terá
    //    credencial válida.
    await ref.read(authRepositoryProvider).logout();
    // 2. Atualiza o estado ANTES de invalidar caches. Assim, os providers de
    //    dados que escutam `authUserIdProvider` (que deriva deste state) já
    //    recomputam com `userId = null` e devolvem listas vazias, sem fazer
    //    nenhum fetch HTTP que falharia com 401.
    state = const AsyncData(AuthState());
    // 3. Desconecta o socket de notificações.
    await ref.read(notificacoesSocketProvider).disconnect();
    // 4. Invalida explicitamente os caches do usuário anterior.
    _invalidateUserScopedProviders();
    // 5. Força a navegação para /login. Não depende apenas do `redirect` do
    //    GoRouter (que poderia não disparar se o `refreshListenable` ainda
    //    não tiver sido conectado, ou em casos de hot-reload).
    try {
      ref.read(routerProvider).go(AppRoutes.login);
    } catch (_) {
      // routerProvider pode não estar disponível em testes — ignorar.
    }
  }

  /// Limpa todos os caches de dados vinculados ao usuário anterior,
  /// evitando vazamento de informação entre contas (defesa em profundidade).
  void _invalidateUserScopedProviders() {
    ref.invalidate(meusImoveisProvider);
    ref.invalidate(imovelDetalheProvider);
    ref.invalidate(associacoesDoImovelProvider);
    ref.invalidate(tarefasProvider);
    ref.invalidate(documentosProvider);
    ref.invalidate(notificacoesControllerProvider);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// ID do usuário autenticado (ou `null`). Usado por providers de dados para
/// invalidar caches automaticamente ao trocar de conta (login/logout).
final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).value?.user?.id;
});
