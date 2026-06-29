import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/common.dart';
import '../../shell/app_drawer.dart';
import 'notificacoes_controller.dart';

class NotificacoesPage extends ConsumerWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificacoesControllerProvider);
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          state.maybeWhen(
            data: (page) => page.naoLidas > 0
                ? TextButton.icon(
                    onPressed: () => ref
                        .read(notificacoesControllerProvider.notifier)
                        .marcarTodasComoLidas(),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Marcar todas'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoading(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(notificacoesControllerProvider.notifier).refresh(),
        ),
        data: (page) => page.itens.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'Sem notificações',
                message:
                    'Você verá aqui avisos sobre tarefas, documentos e imóveis.',
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificacoesControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: page.itens.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _Tile(notificacao: page.itens[i]),
                ),
              ),
      ),
    );
  }
}

class _Tile extends ConsumerWidget {
  const _Tile({required this.notificacao});
  final dynamic notificacao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notificacao;
    final scheme = Theme.of(context).colorScheme;
    final color = _colorFor(n.tipo as String, scheme);
    return Material(
      color: n.lida == true
          ? scheme.surface
          : scheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref
            .read(notificacoesControllerProvider.notifier)
            .marcarComoLida(n.id as String),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(_iconFor(n.tipo as String)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.titulo as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((n.mensagem as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.mensagem as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd/MM HH:mm',
                        'pt_BR',
                      ).format((n.criadaEm as DateTime).toLocal()),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
              if (n.lida == false)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String tipo) {
    if (tipo.startsWith('tarefa')) return Icons.checklist;
    if (tipo.startsWith('documento')) return Icons.description;
    if (tipo.startsWith('associacao')) return Icons.handshake_outlined;
    return Icons.home_work_outlined;
  }

  Color _colorFor(String tipo, ColorScheme scheme) {
    if (tipo.endsWith('rejeitado')) return Colors.redAccent;
    if (tipo.endsWith('aprovado') || tipo.endsWith('concluida')) {
      return Colors.green;
    }
    return scheme.primary;
  }
}
