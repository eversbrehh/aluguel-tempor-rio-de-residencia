import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/common.dart';
import '../auth/presentation/auth_controller.dart';
import '../imoveis/domain/imovel.dart';
import '../imoveis/presentation/imovel_controller.dart';
import 'app_drawer.dart';

final _moeda = NumberFormat.simpleCurrency(locale: 'pt_BR');

class MeusImoveisPage extends ConsumerWidget {
  const MeusImoveisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(meusImoveisProvider);
    final auth = ref.watch(authControllerProvider).value;
    final isProprietario = auth?.user?.isProprietario ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          auth?.user?.nome.isNotEmpty == true
              ? 'Olá, ${auth!.user!.nome.split(" ").first}'
              : 'Meus imóveis',
        ),
      ),
      floatingActionButton: isProprietario
          ? FloatingActionButton.extended(
              onPressed: () => _abrirSheetNovoImovel(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Novo imóvel'),
            )
          : null,
      body: state.when(
        loading: () => const AppLoading(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(meusImoveisProvider),
        ),
        data: (imoveis) {
          if (imoveis.isEmpty) {
            return _EmptyImoveis(
              isProprietario: isProprietario,
              email: auth?.user?.email ?? '',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(meusImoveisProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: imoveis.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ImovelCard(imovel: imoveis[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrirSheetNovoImovel(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _NovoImovelSheet(),
    );
  }
}

class _EmptyImoveis extends StatelessWidget {
  const _EmptyImoveis({required this.isProprietario, required this.email});
  final bool isProprietario;
  final String email;

  @override
  Widget build(BuildContext context) {
    if (isProprietario) {
      return const EmptyState(
        icon: Icons.house_siding,
        title: 'Nenhum imóvel cadastrado',
        message: 'Toque em "Novo imóvel" abaixo para começar.',
      );
    }
    // Comodatário: mostrar o e-mail dele com botão de copiar
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      children: [
        Icon(Icons.mark_email_read_outlined, size: 64, color: scheme.outline),
        const SizedBox(height: 16),
        Text(
          'Aguardando associação',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Para começar, peça ao proprietário do imóvel para associá-lo '
          'usando o e-mail abaixo:',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: scheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SelectableText(
                  email.isEmpty ? '—' : email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: email.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: email));
                          if (context.mounted) {
                            showAppSnack(context, 'E-mail copiado.');
                          }
                        },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar e-mail'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Assim que o proprietário associar você, o imóvel aparecerá aqui '
          'automaticamente.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.outline),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ImovelCard extends StatelessWidget {
  const _ImovelCard({required this.imovel});
  final Imovel imovel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/imoveis/${imovel.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.home_work, color: scheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imovel.titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      imovel.endereco,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (imovel.valorAluguel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _moeda.format(imovel.valorAluguel),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovoImovelSheet extends ConsumerStatefulWidget {
  const _NovoImovelSheet();

  @override
  ConsumerState<_NovoImovelSheet> createState() => _NovoImovelSheetState();
}

class _NovoImovelSheetState extends ConsumerState<_NovoImovelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _endereco = TextEditingController();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titulo.dispose();
    _endereco.dispose();
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final valor = _valor.text.trim().isEmpty
        ? null
        : double.tryParse(_valor.text.trim().replaceAll(',', '.'));
    try {
      await ref
          .read(imovelRepositoryProvider)
          .criar(
            titulo: _titulo.text.trim(),
            endereco: _endereco.text.trim(),
            descricao: _descricao.text.trim().isEmpty
                ? null
                : _descricao.text.trim(),
            valorAluguel: valor,
          );
      ref.invalidate(meusImoveisProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnack(context, 'Imóvel cadastrado com sucesso.');
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
              'Novo imóvel',
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
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Informe um título com pelo menos 2 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _endereco,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Informe um endereço com pelo menos 5 caracteres'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valor,
              decoration: const InputDecoration(
                labelText: 'Valor do aluguel (R\$) — opcional',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                if (parsed == null || parsed < 0) {
                  return 'Valor inválido';
                }
                return null;
              },
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
              label: Text(_submitting ? 'Cadastrando...' : 'Cadastrar imóvel'),
            ),
          ],
        ),
      ),
    );
  }
}
