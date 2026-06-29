/// Entidade de usuário autenticado (snapshot da sessão Supabase).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nome,
    required this.tipo,
    required this.accessToken,
  });

  final String id;
  final String email;
  final String nome;
  final String tipo; // 'proprietario' | 'comodatario'
  final String accessToken;

  bool get isProprietario => tipo == 'proprietario';
  bool get isComodatario => tipo == 'comodatario';
}
