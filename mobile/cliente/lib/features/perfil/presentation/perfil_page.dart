import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final scheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meu perfil')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Sessão não encontrada',
          message: 'Faça login novamente para visualizar suas informações.',
        ),
      );
    }

    final iniciais = _iniciais(user.nome);
    final isProprietario = user.isProprietario;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    iniciais,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.nome.isEmpty ? '—' : user.nome,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Chip(
                  avatar: Icon(
                    isProprietario
                        ? Icons.home_work_outlined
                        : Icons.person_outline,
                    size: 18,
                    color: scheme.primary,
                  ),
                  label: Text(isProprietario ? 'Proprietário' : 'Comodatário'),
                  backgroundColor: scheme.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(
            'Informações da conta',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 8),
          _InfoTile(
            icon: Icons.alternate_email,
            label: 'E-mail',
            value: user.email,
            onCopy: () => _copy(context, user.email, 'E-mail'),
          ),
          _InfoTile(
            icon: Icons.fingerprint,
            label: 'ID do usuário',
            value: user.id,
            onCopy: () => _copy(context, user.id, 'ID'),
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.primary.withValues(alpha: 0.06),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.primary.withValues(alpha: 0.25)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isProprietario
                          ? 'Como proprietário, você pode cadastrar imóveis, '
                                'associar comodatários, criar tarefas e solicitar '
                                'documentos.'
                          : 'Como comodatário, você acessa os imóveis em que '
                                'foi associado, conclui tarefas e envia '
                                'documentos solicitados pelo proprietário.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _confirmarLogout(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }

  String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.characters.first.toUpperCase();
    return (partes.first.characters.first + partes.last.characters.first)
        .toUpperCase();
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      showAppSnack(context, '$label copiado.');
    }
  }

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
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
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.outline),
        ),
        subtitle: SelectableText(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: onCopy == null
            ? null
            : IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copiar',
                onPressed: onCopy,
              ),
      ),
    );
  }
}
