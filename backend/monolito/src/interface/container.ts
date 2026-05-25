import { AssociarComodatario } from '@application/useCases/AssociarComodatario';
import { CriarImovel } from '@application/useCases/CriarImovel';
import { ListarImoveisDoUsuario } from '@application/useCases/ListarImoveisDoUsuario';
import { LoginUsuario } from '@application/useCases/LoginUsuario';
import { ObterImovelPorId } from '@application/useCases/ObterImovelPorId';
import { RegistrarUsuario } from '@application/useCases/RegistrarUsuario';
import { SupabaseAuthService } from '@infrastructure/auth/SupabaseAuthService';
import { AssociacaoRepositorySupabase } from '@infrastructure/repositories/AssociacaoRepositorySupabase';
import { ImovelRepositorySupabase } from '@infrastructure/repositories/ImovelRepositorySupabase';
import { ProfileRepositorySupabase } from '@infrastructure/repositories/ProfileRepositorySupabase';

const authService = new SupabaseAuthService();
const profileRepo = new ProfileRepositorySupabase();
const imovelRepo = new ImovelRepositorySupabase();
const associacaoRepo = new AssociacaoRepositorySupabase();

export const container = {
  authService,
  profileRepo,
  imovelRepo,
  associacaoRepo,

  registrarUsuario: new RegistrarUsuario(authService),
  loginUsuario: new LoginUsuario(authService),
  criarImovel: new CriarImovel(imovelRepo, profileRepo),
  listarImoveisDoUsuario: new ListarImoveisDoUsuario(imovelRepo, profileRepo),
  obterImovelPorId: new ObterImovelPorId(imovelRepo, associacaoRepo),
  associarComodatario: new AssociarComodatario(imovelRepo, profileRepo, associacaoRepo),
};
