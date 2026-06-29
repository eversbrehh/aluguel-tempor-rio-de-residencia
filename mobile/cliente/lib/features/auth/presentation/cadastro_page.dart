import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class CadastroPage extends ConsumerStatefulWidget {
  const CadastroPage({super.key});

  @override
  ConsumerState<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends ConsumerState<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String _tipo = 'comodatario';

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            password: _senha.text,
            tipo: _tipo,
          );
      // Em caso de sucesso o router redireciona, desmontando este widget;
      // não tocamos em `ref` depois daqui.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nome,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe seu nome'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Informe o e-mail';
                        if (!v.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senha,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe uma senha';
                        if (v.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Eu sou:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    RadioListTile<String>(
                      title: const Text('Comodatário (vou alugar um imóvel)'),
                      value: 'comodatario',
                      groupValue: _tipo,
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Proprietário (vou cadastrar imóveis)'),
                      value: 'proprietario',
                      groupValue: _tipo,
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
