export class DomainError extends Error {
  constructor(
    public readonly code: string,
    message: string,
    public readonly status: number = 400,
  ) {
    super(message);
    this.name = 'DomainError';
  }
}

export class NotFoundError extends DomainError {
  constructor(message = 'Recurso não encontrado') {
    super('NOT_FOUND', message, 404);
  }
}

export class ForbiddenError extends DomainError {
  constructor(message = 'Acesso negado') {
    super('FORBIDDEN', message, 403);
  }
}

export class ConflictError extends DomainError {
  constructor(message = 'Conflito de estado') {
    super('CONFLICT', message, 409);
  }
}
