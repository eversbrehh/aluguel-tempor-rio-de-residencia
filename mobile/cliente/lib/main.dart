import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const ProviderScope(child: LamdClienteApp()));
}

class LamdClienteApp extends ConsumerStatefulWidget {
  const LamdClienteApp({super.key});

  @override
  ConsumerState<LamdClienteApp> createState() => _LamdClienteAppState();
}

class _LamdClienteAppState extends ConsumerState<LamdClienteApp> {
  @override
  void initState() {
    super.initState();
    // Configura o handler de 401: faz logout e força navegação para /login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unauthorizedHandlerProvider.notifier).set(() async {
        await ref.read(authControllerProvider.notifier).logout();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'LAMD Cliente',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
    );
  }
}
