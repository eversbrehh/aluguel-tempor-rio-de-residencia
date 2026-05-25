/**
 * Erro base do domínio. Permite mapear para status HTTP no error handler.
 */
export class DomainError extends Error {
  public readonly status: number;
  public readonly code: string;

  constructor(message: string, status = 400, code = 'DOMAIN_ERROR') {
    super(message);
    this.name = 'DomainError';
    this.status = status;
    this.code = code;
  }
}

export class NotFoundError extends DomainError {
  constructor(message = 'Recurso não encontrado') {
    super(message, 404, 'NOT_FOUND');
    this.name = 'NotFoundError';
  }
}

export class UnauthorizedError extends DomainError {
  constructor(message = 'Não autenticado') {
    super(message, 401, 'UNAUTHORIZED');
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends DomainError {
  constructor(message = 'Acesso negado') {
    super(message, 403, 'FORBIDDEN');
    this.name = 'ForbiddenError';
  }
}

export class ConflictError extends DomainError {
  constructor(message = 'Conflito de estado') {
    super(message, 409, 'CONFLICT');
    this.name = 'ConflictError';
  }
}
