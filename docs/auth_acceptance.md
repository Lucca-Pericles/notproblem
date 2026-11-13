# Validação — Configurar acesso e base do sistema

## Critérios automatizados

| Critério | Evidência |
| --- | --- |
| Usuário sem sessão não acessa a página inicial | `widget_test.dart`: exibe a página de entrada sem sessão |
| Login válido abre a página inicial | `widget_test.dart`: autentica e exibe o nome do usuário |
| Logout encerra a sessão | `widget_test.dart`: volta para a página de entrada |
| Cadastro exige dados válidos | `widget_test.dart`: valida nome, e-mail e senha |
| Nenhum segredo é versionado | configuração real ignorada por `.gitignore`; apenas o exemplo é commitado |

## Validação manual

1. Aplicar `supabase/migrations/202611130001_initial_auth.sql` no projeto Supabase.
2. Executar o aplicativo com `--dart-define-from-file=config/dev.json`.
3. Cadastrar nome, e-mail e uma senha válida.
4. Confirmar o e-mail, caso essa opção esteja ativa no Supabase.
5. Entrar e verificar a saudação com o nome cadastrado.
6. Abrir uma rota privada sem sessão e confirmar o redirecionamento para entrar.
7. Sair e confirmar que o painel deixa de ser exibido.
8. Verificar no banco que `public.profiles` não possui coluna de senha.
9. Conferir que um usuário não consegue ler ou alterar o perfil de outro usuário.

## Checklist da Definition of Done

- [x] Implementação e testes adicionados à branch da história.
- [x] Critérios de aceite cobertos por teste ou roteiro manual.
- [x] Nenhum dado sensível incluído no código ou em logs.
- [ ] Revisão por outro integrante.
- [ ] Migração aplicada e fluxo demonstrado no ambiente publicado.
- [ ] Merge realizado após a aprovação da revisão.
