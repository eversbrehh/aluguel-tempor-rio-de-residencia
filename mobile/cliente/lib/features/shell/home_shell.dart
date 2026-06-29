import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../notificacoes/presentation/notificacoes_controller.dart';

/// Shell com bottom-nav que envolve as rotas principais (home + notificações).
///
/// O `Drawer` é provido pelas próprias páginas filhas (via `AppDrawer`),
/// pois `Scaffold.of(...)` só alcança o Scaffold mais próximo na árvore.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final isNotif = location.startsWith(AppRoutes.notificacoes);
    final naoLidas = ref
        .watch(notificacoesControllerProvider)
        .maybeWhen(data: (p) => p.naoLidas, orElse: () => 0);

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: isNotif ? 1 : 0,
        onDestinationSelected: (i) {
          if (i == 0) context.go(AppRoutes.home);
          if (i == 1) context.go(AppRoutes.notificacoes);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Imóveis',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notificações',
          ),
        ],
      ),
    );
  }
}
