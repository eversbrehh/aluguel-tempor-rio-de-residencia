import 'package:flutter/foundation.dart' show kIsWeb;

/// Configurações de runtime do app.
///
/// Estes valores podem ser sobrescritos em build/test usando
/// `--dart-define` (`flutter run --dart-define=MONOLITO_BASE_URL=...`).
///
/// Default por plataforma:
/// - **Web** (Chrome/Edge): `http://localhost:<porta>` — o navegador resolve
///   diretamente o backend que roda na mesma máquina.
/// - **Emulador Android**: `http://10.0.2.2:<porta>` — alias do AVD para o
///   `localhost` do host.
class AppEnv {
  const AppEnv._();

  static const String _hostWeb = 'localhost';
  static const String _hostAndroid = '10.0.2.2';

  /// Host default segundo a plataforma de execução.
  static String get _defaultHost => kIsWeb ? _hostWeb : _hostAndroid;

  static const String _monolitoOverride = String.fromEnvironment(
    'MONOLITO_BASE_URL',
  );
  static const String _notificacoesOverride = String.fromEnvironment(
    'NOTIFICACOES_BASE_URL',
  );
  static const String _notificacoesWsOverride = String.fromEnvironment(
    'NOTIFICACOES_WS_URL',
  );
  static const String _tarefaOverride = String.fromEnvironment(
    'TAREFA_BASE_URL',
  );
  static const String _documentoOverride = String.fromEnvironment(
    'DOCUMENTO_BASE_URL',
  );

  /// URL base do monolito (auth + imóveis + associações).
  static String get monolitoBaseUrl => _monolitoOverride.isNotEmpty
      ? _monolitoOverride
      : 'http://$_defaultHost:3000/api/v1';

  /// URL base do MS Notificações (REST).
  static String get notificacoesBaseUrl => _notificacoesOverride.isNotEmpty
      ? _notificacoesOverride
      : 'http://$_defaultHost:3001/api/v1';

  /// Endpoint Socket.IO do MS Notificações (origem, sem path).
  static String get notificacoesWsUrl => _notificacoesWsOverride.isNotEmpty
      ? _notificacoesWsOverride
      : 'http://$_defaultHost:3001';

  /// URL base do MS Tarefa.
  static String get tarefaBaseUrl => _tarefaOverride.isNotEmpty
      ? _tarefaOverride
      : 'http://$_defaultHost:3002/api/v1';

  /// URL base do MS Documento.
  static String get documentoBaseUrl => _documentoOverride.isNotEmpty
      ? _documentoOverride
      : 'http://$_defaultHost:3003/api/v1';

  /// Timeout padrão das chamadas HTTP.
  static const Duration httpTimeout = Duration(seconds: 15);
}
