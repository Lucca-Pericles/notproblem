# Validação — Configurar acesso e base do sistema

## Critérios automatizados

| Critério | Evidência |
| --- | --- |
| Usuário sem sessão não acessa a página inicial | `widget_test.dart`: exibe a página de entrada sem sessão |
| Conta sem e-mail confirmado não acessa área privada | `widget_test.dart`: sessão pendente mantém a página de entrada |
| Link de confirmação aponta ao site | `SupabaseAuthRepository` envia `emailRedirectTo`; README registra a allowlist necessária |
| Confirmação exibe tela de sucesso | `widget_test.dart`: tela E-mail confirmado leva ao login |
| Login válido abre a página inicial | `widget_test.dart`: autentica e exibe o nome do usuário |
| Logout encerra a sessão | `widget_test.dart`: volta para a página de entrada |
| Cadastro exige dados válidos | `widget_test.dart`: valida nome, e-mail e senha |
| Nenhum segredo é versionado | configuração real ignorada por `.gitignore`; apenas o exemplo é commitado |

## Validação manual

1. Aplicar `supabase/migrations/202611130001_initial_auth.sql` no projeto Supabase.
2. Executar o aplicativo com `--dart-define-from-file=config/dev.json`.
3. Cadastrar nome, e-mail e uma senha válida.
4. No Supabase, manter **Confirm email** ativo e cadastrar
   `https://SEU-DOMINIO/#/email-confirmado` nas Redirect URLs.
5. Cadastrar uma conta e verificar que o link recebido retorna para a tela
   **E-mail confirmado** do site.
6. Selecionar **Ir para login**, entrar com a conta confirmada e verificar a
   saudação com o nome cadastrado.
7. Tentar entrar antes de confirmar e verificar que o acesso é recusado.
8. Abrir uma rota privada sem sessão e confirmar o redirecionamento para entrar.
9. Sair e confirmar que o painel deixa de ser exibido.
10. Verificar no banco que `public.profiles` não possui coluna de senha.
11. Conferir que um usuário não consegue ler ou alterar o perfil de outro usuário.

## Checklist da Definition of Done

- [x] Implementação e testes adicionados à branch da história.
- [x] Critérios de aceite cobertos por teste ou roteiro manual.
- [x] Nenhum dado sensível incluído no código ou em logs.
- [X] Revisão por outro integrante.
- [X] Migração aplicada e fluxo demonstrado no ambiente publicado.
- [X] Merge realizado após a aprovação da revisão.
