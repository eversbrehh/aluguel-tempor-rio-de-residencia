import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../documentos/presentation/documentos_tab.dart';
import '../../tarefas/presentation/tarefas_tab.dart';
import '../domain/imovel.dart';
import 'imovel_controller.dart';

final _moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
final _dateOut = DateFormat('dd/MM/yyyy', 'pt_BR');

String _fmtData(String iso) {
  try {
    return _dateOut.format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

class ImovelDetalhePage extends ConsumerWidget {
  const ImovelDetalhePage({super.key, required this.imovelId});
  final String imovelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imovel = ref.watch(imovelDetalheProvider(imovelId));
    final assoc = ref.watch(associacoesDoImovelProvider(imovelId));
    final auth = ref.watch(authControllerProvider).value;
    final isProprietario = auth?.user?.isProprietario ?? false;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: imovel.maybeWhen(
            data: (i) => Text(i.titulo),
            orElse: () => const Text('Imóvel'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Resumo', icon: Icon(Icons.info_outline)),
              Tab(text: 'Tarefas', icon: Icon(Icons.checklist)),
              Tab(text: 'Documentos', icon: Icon(Icons.folder_outlined)),
            ],
          ),
        ),
        body: imovel.when(
          loading: () => const AppLoading(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(imovelDetalheProvider(imovelId)),
          ),
          data: (im) {
            final associacoesData = assoc.maybeWhen(
              data: (l) => l,
              orElse: () => <Associacao>[],
            );
            final associacaoAtual = _escolheAssociacao(
              associacoesData,
              auth?.user?.id,
            );
            final associacaoId = associacaoAtual?.id ?? '';

            return TabBarView(
              children: [
                _Resumo(
                  imovel: im,
                  associacao: associacaoAtual,
                  isProprietario: isProprietario,
                ),
                TarefasTab(associacaoId: associacaoId, imovelId: im.id),
                DocumentosTab(associacaoId: associacaoId),
              ],
            );
          },
        ),
      ),
    );
  }

  Associacao? _escolheAssociacao(List<Associacao> lista, String? userId) {
    if (lista.isEmpty) return null;
    if (userId == null) return lista.first;
    return lista.firstWhere(
      (a) => a.comodatarioId == userId,
      orElse: () => lista.first,
    );
  }
}

class _Resumo extends ConsumerWidget {
  const _Resumo({
    required this.imovel,
    required this.associacao,
    required this.isProprietario,
  });
  final Imovel imovel;
  final Associacao? associacao;
  final bool isProprietario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(imovelDetalheProvider(imovel.id));
        ref.invalidate(associacoesDoImovelProvider(imovel.id));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imovel.titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: scheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(imovel.endereco)),
                    ],
                  ),
                  if (imovel.valorAluguel != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 18,
                          color: scheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _moeda.format(imovel.valorAluguel),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  if ((imovel.descricao ?? '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      imovel.descricao!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CardComodato(
            imovelId: imovel.id,
            associacao: associacao,
            isProprietario: isProprietario,
          ),
        ],
      ),
    );
  }
}

class _CardComodato extends ConsumerWidget {
  const _CardComodato({
    required this.imovelId,
    required this.associacao,
    required this.isProprietario,
  });
  final String imovelId;
  final Associacao? associacao;
  final bool isProprietario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (associacao != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'Comodato ativo',
                icon: Icons.handshake_outlined,
              ),
              const SizedBox(height: 8),
              if (associacao!.comodatarioNome != null)
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: scheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        associacao!.comodatarioNome!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event_available, size: 18, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text('Início: ${_fmtData(associacao!.dataInicio)}'),
                ],
              ),
              if (associacao!.dataFim != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.event_busy, size: 18, color: scheme.outline),
                    const SizedBox(width: 6),
                    Text('Fim previsto: ${_fmtData(associacao!.dataFim!)}'),
                  ],
                ),
              ],
              if (isProprietario) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: () => _confirmarEncerrar(context, ref),
                    icon: const Icon(Icons.event_busy),
                    label: const Text('Encerrar associação'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Sem associação
    if (!isProprietario) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'Sem associação ativa',
        message:
            'Quando o imóvel for associado, as tarefas e documentos aparecerão nas abas acima.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              'Sem comodatário associado',
              icon: Icons.handshake_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              'Associe um comodatário pelo e-mail dele para criar tarefas '
              'e compartilhar documentos.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _abrirSheetAssociar(context, ref),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Associar comodatário'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirSheetAssociar(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AssociarSheet(imovelId: imovelId),
    );
  }

  Future<void> _confirmarEncerrar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar associação?'),
        content: const Text(
          'O comodatário deixará de ter acesso ao imóvel. '
          'Esta ação não pode ser desfeita.',
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
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    if (ok != true || associacao == null) return;
    try {
      await ref
          .read(imovelRepositoryProvider)
          .encerrarAssociacao(imovelId: imovelId, associacaoId: associacao!.id);
      ref.invalidate(associacoesDoImovelProvider(imovelId));
      if (context.mounted) {
        showAppSnack(context, 'Associação encerrada.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, e.toString(), isError: true);
      }
    }
  }
}

class _AssociarSheet extends ConsumerStatefulWidget {
  const _AssociarSheet({required this.imovelId});
  final String imovelId;

  @override
  ConsumerState<_AssociarSheet> createState() => _AssociarSheetState();
}

class _AssociarSheetState extends ConsumerState<_AssociarSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _submitting = false;

  static final _iso = DateFormat('yyyy-MM-dd');
  static final _br = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dataInicio = picked;
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = null;
        }
      });
    }
  }

  Future<void> _pickFim() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio.add(const Duration(days: 30)),
      firstDate: _dataInicio,
      lastDate: _dataInicio.add(const Duration(days: 365 * 10)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _dataFim = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(imovelRepositoryProvider)
          .associarComodatario(
            imovelId: widget.imovelId,
            comodatarioEmail: _email.text.trim(),
            dataInicio: _iso.format(_dataInicio),
            dataFim: _dataFim != null ? _iso.format(_dataFim!) : null,
          );
      ref.invalidate(associacoesDoImovelProvider(widget.imovelId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Comodatário associado com sucesso.');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      // Erros de domínio comuns
      final friendly =
          msg.contains('não encontrado') ||
              msg.contains('not found') ||
              msg.contains('404')
          ? 'Não existe um comodatário cadastrado com esse e-mail.'
          : msg;
      showAppSnack(context, friendly, isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + insets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Associar comodatário',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'O comodatário precisa estar cadastrado no app.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'E-mail do comodatário',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Informe o e-mail';
                final ok = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value);
                return ok ? null : 'E-mail inválido';
              },
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Data de início',
              value: _br.format(_dataInicio),
              icon: Icons.event_available,
              onTap: _pickInicio,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Data de fim (opcional)',
              value: _dataFim != null ? _br.format(_dataFim!) : '—',
              icon: Icons.event_busy,
              onTap: _pickFim,
              onClear: _dataFim == null
                  ? null
                  : () => setState(() => _dataFim = null),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(_submitting ? 'Associando...' : 'Associar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : const Icon(Icons.calendar_month),
        ),
        child: Text(value),
      ),
    );
  }
}
