import { IAuthService, RegisterInput } from '@domain/services/IAuthService';

export class RegistrarUsuario {
  constructor(private readonly authService: IAuthService) {}

  async execute(input: RegisterInput): Promise<{ userId: string; email: string }> {
    return this.authService.register(input);
  }
}
