import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/documento.dart';
import 'documentos_controller.dart';

const _tiposComuns = <String, String>{
  'contrato': 'Contrato',
  'comprovante_residencia': 'Comprovante de residência',
  'comprovante_renda': 'Comprovante de renda',
  'documento_identidade': 'Documento de identidade',
  'fiador': 'Documentos do fiador',
};

String _labelTipo(String tipo) =>
    _tiposComuns[tipo] ?? tipo.replaceAll('_', ' ');

class DocumentosTab extends ConsumerWidget {
  const DocumentosTab({super.key, required this.associacaoId});

  final String associacaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = associacaoId.isEmpty ? null : associacaoId;
    final state = ref.watch(documentosProvider(arg));
    final isProprietario =
        ref.watch(authControllerProvider).value?.user?.isProprietario ?? false;

    return Scaffold(
      floatingActionButton: (isProprietario && associacaoId.isNotEmpty)
          ? FloatingActionButton.extended(
              onPressed: () => _abrirSheetSolicitar(context, ref, arg),
              icon: const Icon(Icons.post_add),
              label: const Text('Solicitar documento'),
            )
          : null,
      body: state.when(
        loading: () => const AppLoading(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(documentosProvider(arg)),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              title: 'Nenhum documento por aqui',
              message: associacaoId.isEmpty
                  ? 'É preciso ter um comodatário associado antes de solicitar documentos.'
                  : isProprietario
                  ? 'Toque em "Solicitar documento" para pedir o primeiro.'
                  : 'O proprietário ainda não solicitou documentos.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(documentosProvider(arg)),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DocCard(
                doc: docs[i],
                isProprietario: isProprietario,
                onChanged: () => ref.invalidate(documentosProvider(arg)),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirSheetSolicitar(
    BuildContext context,
    WidgetRef ref,
    String? arg,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _SolicitarDocumentoSheet(associacaoId: associacaoId, arg: arg),
    );
  }
}

class _SolicitarDocumentoSheet extends ConsumerStatefulWidget {
  const _SolicitarDocumentoSheet({
    required this.associacaoId,
    required this.arg,
  });
  final String associacaoId;
  final String? arg;

  @override
  ConsumerState<_SolicitarDocumentoSheet> createState() =>
      _SolicitarDocumentoSheetState();
}

class _SolicitarDocumentoSheetState
    extends ConsumerState<_SolicitarDocumentoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _tipoOutro = TextEditingController();
  String _tipoSelecionado = 'contrato';
  bool _isOutro = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titulo.dispose();
    _tipoOutro.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tipo = _isOutro
        ? _tipoOutro.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')
        : _tipoSelecionado;
    setState(() => _submitting = true);
    try {
      await ref
          .read(documentoRepositoryProvider)
          .solicitar(
            associacaoId: widget.associacaoId,
            tipo: tipo,
            titulo: _titulo.text.trim(),
          );
      ref.invalidate(documentosProvider(widget.arg));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Documento solicitado.');
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
              'Solicitar documento',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título visível ao comodatário',
                prefixIcon: Icon(Icons.title),
                hintText: 'Ex.: Comprovante de residência atualizado',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _isOutro ? '__outro__' : _tipoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Tipo do documento',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                ..._tiposComuns.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
                const DropdownMenuItem(
                  value: '__outro__',
                  child: Text('Outro...'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  if (v == '__outro__') {
                    _isOutro = true;
                  } else {
                    _isOutro = false;
                    _tipoSelecionado = v;
                  }
                });
              },
            ),
            if (_isOutro) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoOutro,
                decoration: const InputDecoration(
                  labelText: 'Especifique o tipo',
                  prefixIcon: Icon(Icons.edit_outlined),
                  helperText:
                      'Use um identificador curto. Ex.: declaracao_imposto',
                ),
                validator: (v) {
                  if (!_isOutro) return null;
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Informe o tipo';
                  if (value.length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Solicitando...' : 'Solicitar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocCard extends ConsumerStatefulWidget {
  const _DocCard({
    required this.doc,
    required this.isProprietario,
    required this.onChanged,
  });

  final Documento doc;
  final bool isProprietario;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DocCard> createState() => _DocCardState();
}

class _DocCardState extends ConsumerState<_DocCard> {
  bool _busyEnviar = false;
  bool _busyBaixar = false;
  bool _busyAprovar = false;
  bool _busyRejeitar = false;

  Future<void> _enviar() async {
    final res = await FilePicker.platform.pickFiles(withData: true);
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    if (f.bytes == null) return;
    setState(() => _busyEnviar = true);
    try {
      await ref
          .read(documentoRepositoryProvider)
          .upload(
            documentoId: widget.doc.id,
            bytes: f.bytes!,
            fileName: f.name,
          );
      widget.onChanged();
      if (mounted) showAppSnack(context, 'Documento enviado.');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyEnviar = false);
    }
  }

  Future<void> _baixar() async {
    setState(() => _busyBaixar = true);
    try {
      final url = await ref
          .read(documentoRepositoryProvider)
          .downloadUrl(widget.doc.id);
      if (url.isEmpty) {
        if (mounted) {
          showAppSnack(context, 'Link indisponível.', isError: true);
        }
        return;
      }
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!ok && mounted) {
        showAppSnack(context, 'Não foi possível abrir o link.', isError: true);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyBaixar = false);
    }
  }

  Future<void> _aprovar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprovar documento?'),
        content: Text(
          'O documento "${widget.doc.titulo}" será marcado como aprovado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyAprovar = true);
    try {
      await ref.read(documentoRepositoryProvider).aprovar(widget.doc.id);
      widget.onChanged();
      if (mounted) showAppSnack(context, 'Documento aprovado.');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyAprovar = false);
    }
  }

  Future<void> _rejeitar() async {
    final obs = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar documento'),
        content: TextField(
          controller: obs,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
            hintText: 'Explique para o comodatário o que ajustar',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busyRejeitar = true);
    try {
      await ref
          .read(documentoRepositoryProvider)
          .rejeitar(
            widget.doc.id,
            observacao: obs.text.trim().isEmpty ? null : obs.text.trim(),
          );
      widget.onChanged();
      if (mounted) showAppSnack(context, 'Documento rejeitado.');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyRejeitar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (doc.status) {
      'aprovado' => Colors.green,
      'rejeitado' => Colors.redAccent,
      'enviado' => Colors.orange,
      _ => scheme.primary,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.titulo,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _labelTipo(doc.tipo),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                      ),
                      if (doc.fileName != null && doc.fileName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 14,
                                color: scheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  doc.fileName!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                StatusChip(label: _label(doc.status), color: color),
              ],
            ),
            if ((doc.observacao ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.isProprietario
                            ? 'Motivo informado: ${doc.observacao!}'
                            : 'Motivo do proprietário: ${doc.observacao!}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!widget.isProprietario && doc.podeEnviar)
                  FilledButton.icon(
                    onPressed: _busyEnviar ? null : _enviar,
                    icon: _busyEnviar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(_busyEnviar ? 'Enviando...' : 'Enviar arquivo'),
                  ),
                if (doc.podeBaixar)
                  OutlinedButton.icon(
                    onPressed: _busyBaixar ? null : _baixar,
                    icon: _busyBaixar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_busyBaixar ? 'Abrindo...' : 'Baixar'),
                  ),
                if (widget.isProprietario && doc.status == 'enviado') ...[
                  FilledButton.icon(
                    onPressed: _busyAprovar ? null : _aprovar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: _busyAprovar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(_busyAprovar ? 'Aprovando...' : 'Aprovar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busyRejeitar ? null : _rejeitar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    icon: _busyRejeitar
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close),
                    label: Text(_busyRejeitar ? 'Rejeitando...' : 'Rejeitar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(String s) => switch (s) {
    'solicitado' => 'Solicitado',
    'enviado' => 'Enviado',
    'aprovado' => 'Aprovado',
    'rejeitado' => 'Rejeitado',
    _ => s,
  };
}
