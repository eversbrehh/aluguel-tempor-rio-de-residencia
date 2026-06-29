/// Exceções de domínio do app cliente.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Sessão expirada. Faça login novamente.']);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.status});
  final int? status;
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
