# SYN-20 — Registrar causa provável e plano de ação

## Fluxo entregue

1. Conclua os 5 Porquês de uma ocorrência.
2. Selecione **Registrar causa e plano de ação**.
3. Revise a causa provável sugerida pela quinta resposta.
4. Informe ação, responsável, prazo, resultado esperado e indicador.
5. Salve o plano como rascunho e siga para a revisão da investigação.
6. Após concluir a revisão, abra novamente a ocorrência para acompanhar a ação.

## Critérios verificados

- A causa é inicialmente baseada na quinta resposta e permanece editável
  enquanto a investigação estiver em revisão.
- A interface informa que a causa é uma hipótese da equipe e não uma certeza do
  sistema.
- Todos os campos e o prazo são obrigatórios.
- O prazo não pode ser anterior à data atual em `America/Sao_Paulo`.
- Ocorrência, investigação, causa e ação permanecem vinculadas no banco.
- Somente investigações concluídas aceitam um plano.
- Existe somente um plano por ocorrência neste MVP.
- O salvamento cria um plano com status **Em revisão** e mantém a ocorrência
  **Em investigação**.
- Somente a conclusão integral descrita na SYN-21 muda a ocorrência para
  **Ação planejada**.
- RLS restringe leitura, criação e edição ao usuário autenticado proprietário.

## Verificação automatizada

```powershell
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

Os testes cobrem hipótese sugerida, bloqueio da investigação incompleta,
validação, vínculo, salvamento, edição do rascunho, retomada sem duplicação e
acesso direto. As migrações relacionadas são
`supabase/migrations/202611230002_create_action_plans.sql` e
`supabase/migrations/202611240001_review_and_conclude_investigations.sql`.
