// Smoke test do app: garante que o widget root renderiza a tela de login sem erros.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lamd_cliente/main.dart';

void main() {
  testWidgets('App inicia sem erros', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LamdClienteApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
