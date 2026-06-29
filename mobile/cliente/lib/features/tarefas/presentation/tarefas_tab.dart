import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/tarefa.dart';
import 'tarefas_controller.dart';

final _br = DateFormat('dd/MM/yyyy', 'pt_BR');
final _iso = DateFormat('yyyy-MM-dd');

String _fmtPrazo(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    return _br.format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

bool _estaAtrasada(Tarefa t) {
  if (t.status != 'pendente' || t.prazo == null) return false;
  try {
    final d = DateTime.parse(t.prazo!);
    final hoje = DateTime.now();
    final hojeData = DateTime(hoje.year, hoje.month, hoje.day);
    return d.isBefore(hojeData);
  } catch (_) {
    return false;
  }
}

class TarefasTab extends ConsumerWidget {
  const TarefasTab({
    super.key,
    required this.associacaoId,
    required this.imovelId,
  });

  final String associacaoId;
  final String imovelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TarefasListArgs(
      associacaoId: associacaoId.isEmpty ? null : associacaoId,
      imovelId: imovelId,
    );
    final state = ref.watch(tarefasProvider(args));
    final auth = ref.watch(authControllerProvider).value;
    final isProprietario = auth?.user?.isProprietario ?? false;

    return Scaffold(
      floatingActionButton: (isProprietario && associacaoId.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _abrirCriarTarefa(context, ref, args),
              icon: const Icon(Icons.add_task),
              label: const Text('Nova tarefa'),
            )
          : null,
      body: state.when(
        loading: () => const AppLoading(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(tarefasProvider(args)),
        ),
        data: (tarefas) {
          if (tarefas.isEmpty) {
            return EmptyState(
              icon: Icons.checklist,
              title: 'Nenhuma tarefa por aqui',
              message: associacaoId.isEmpty
                  ? 'É preciso ter um comodatário associado antes de criar tarefas.'
                  : isProprietario
                  ? 'Toque em "Nova tarefa" para criar a primeira.'
                  : 'O proprietário ainda não criou tarefas para você.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tarefasProvider(args)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: tarefas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TarefaCard(
                tarefa: tarefas[i],
                isComodatario: !isProprietario,
                onConcluido: () => ref.invalidate(tarefasProvider(args)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirCriarTarefa(
    BuildContext context,
    WidgetRef ref,
    TarefasListArgs args,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NovaTarefaSheet(associacaoId: associacaoId, args: args),
    );
  }
}

class _NovaTarefaSheet extends ConsumerStatefulWidget {
  const _NovaTarefaSheet({required this.associacaoId, required this.args});
  final String associacaoId;
  final TarefasListArgs args;

  @override
  ConsumerState<_NovaTarefaSheet> createState() => _NovaTarefaSheetState();
}

class _NovaTarefaSheetState extends ConsumerState<_NovaTarefaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  String _recorrencia = 'unica';
  DateTime? _prazo;
  bool _submitting = false;

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickPrazo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _prazo ?? now,
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _prazo = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(tarefaRepositoryProvider)
          .criar(
            associacaoId: widget.associacaoId,
            titulo: _titulo.text.trim(),
            descricao: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
            recorrencia: _recorrencia,
            prazo: _prazo == null ? null : _iso.format(_prazo!),
          );
      ref.invalidate(tarefasProvider(widget.args));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Tarefa criada com sucesso.');
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + insets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nova tarefa',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _recorrencia,
              decoration: const InputDecoration(
                labelText: 'Recorrência',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: 'unica', child: Text('Única')),
                DropdownMenuItem(value: 'diaria', child: Text('Diária')),
                DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                DropdownMenuItem(value: 'mensal', child: Text('Mensal')),
              ],
              onChanged: (v) => setState(() => _recorrencia = v ?? 'unica'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickPrazo,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Prazo (opcional)',
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: _prazo == null
                      ? const Icon(Icons.calendar_month)
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _prazo = null),
                        ),
                ),
                child: Text(_prazo == null ? 'Sem prazo' : _br.format(_prazo!)),
              ),
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
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Criando...' : 'Criar tarefa'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarefaCard extends ConsumerStatefulWidget {
  const _TarefaCard({
    required this.tarefa,
    required this.isComodatario,
    required this.onConcluido,
  });

  final Tarefa tarefa;
  final bool isComodatario;
  final VoidCallback onConcluido;

  @override
  ConsumerState<_TarefaCard> createState() => _TarefaCardState();
}

class _TarefaCardState extends ConsumerState<_TarefaCard> {
  bool _concluindo = false;

  Future<void> _concluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como concluída?'),
        content: Text(
          'A tarefa "${widget.tarefa.titulo}" será marcada como concluída.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _concluindo = true);
    try {
      await ref.read(tarefaRepositoryProvider).concluir(widget.tarefa.id);
      widget.onConcluido();
      if (mounted) {
        showAppSnack(context, 'Tarefa concluída.');
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _concluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarefa;
    final scheme = Theme.of(context).colorScheme;
    final atrasada = _estaAtrasada(t);
    final color = t.status == 'concluida'
        ? Colors.green
        : t.status == 'arquivada'
        ? scheme.outline
        : atrasada
        ? scheme.error
        : scheme.primary;

    return Card(
      shape: atrasada
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (atrasada) ...[
                  Icon(Icons.warning_amber_rounded, color: scheme.error),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    t.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: t.status == 'concluida'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                StatusChip(
                  label: atrasada ? 'Atrasada' : _statusLabel(t.status),
                  color: color,
                ),
              ],
            ),
            if ((t.descricao ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(t.descricao!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _meta(context, Icons.repeat, _recorrenciaLabel(t.recorrencia)),
                if (t.prazo != null)
                  _meta(
                    context,
                    Icons.event,
                    'Prazo: ${_fmtPrazo(t.prazo)}',
                    color: atrasada ? scheme.error : null,
                  ),
                if (t.concluidaEm != null)
                  _meta(
                    context,
                    Icons.check_circle_outline,
                    'Concluída em ${_br.format(t.concluidaEm!)}',
                    color: Colors.green,
                  ),
              ],
            ),
            if (widget.isComodatario && t.isPendente) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _concluindo ? null : _concluir,
                  icon: _concluindo
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _concluindo ? 'Concluindo...' : 'Marcar como concluída',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meta(
    BuildContext context,
    IconData icon,
    String text, {
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: c,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  String _statusLabel(String s) => switch (s) {
    'concluida' => 'Concluída',
    'arquivada' => 'Arquivada',
    _ => 'Pendente',
  };

  String _recorrenciaLabel(String r) => switch (r) {
    'diaria' => 'Diária',
    'semanal' => 'Semanal',
    'mensal' => 'Mensal',
    _ => 'Única',
  };
}
