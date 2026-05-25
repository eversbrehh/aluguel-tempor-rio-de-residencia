import { AuthSession, IAuthService } from '@domain/services/IAuthService';

export class LoginUsuario {
  constructor(private readonly authService: IAuthService) {}

  async execute(email: string, password: string): Promise<AuthSession> {
    return this.authService.login(email, password);
  }
}
