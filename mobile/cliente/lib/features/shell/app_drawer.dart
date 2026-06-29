import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../auth/presentation/auth_controller.dart';

/// Drawer compartilhado pelas páginas principais (Meus imóveis / Notificações).
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(
                  (auth?.user?.nome ?? '?').characters.first.toUpperCase(),
                ),
              ),
              title: Text(auth?.user?.nome ?? '—'),
              subtitle: Text(auth?.user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Meu perfil'),
              subtitle: const Text('Ver informações da conta'),
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.perfil);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Sair', style: TextStyle(color: scheme.error)),
              onTap: () async {
                // Fecha o drawer ANTES de abrir o diálogo para evitar
                // que o `Navigator.pop` posterior remova a página atual.
                final navigator = Navigator.of(context);
                if (navigator.canPop()) navigator.pop();

                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sair da conta?'),
                    content: const Text(
                      'Você será desconectado e precisará fazer login novamente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sair'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  GoRouter.of(context).go(AppRoutes.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
