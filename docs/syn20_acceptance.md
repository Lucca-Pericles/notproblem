# SYN-20 — Registrar causa provável e plano de ação

## Fluxo entregue

1. Conclua os 5 Porquês de uma ocorrência.
2. Selecione **Registrar causa e plano de ação**.
3. Revise a causa provável sugerida pela quinta resposta.
4. Informe ação, responsável, prazo, resultado esperado e indicador.
5. Salve e confira o resumo do plano.
6. Abra novamente a ocorrência para consultar o plano já registrado.

## Critérios verificados

- A causa é inicialmente baseada na quinta resposta, mas permanece editável
  antes do salvamento.
- A interface informa que a causa é uma hipótese da equipe e não uma certeza do
  sistema.
- Todos os campos e o prazo são obrigatórios.
- O prazo não pode ser anterior à data atual em `America/Sao_Paulo`.
- Ocorrência, investigação, causa e ação permanecem vinculadas no banco.
- Somente investigações concluídas aceitam um plano.
- Existe somente um plano por ocorrência neste MVP.
- O registro muda a ocorrência para o status **Ação planejada**.
- RLS restringe leitura e criação ao usuário autenticado proprietário.

## Verificação automatizada

```powershell
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

Os testes cobrem hipótese sugerida, bloqueio da investigação incompleta,
validação, vínculo, salvamento, retomada sem duplicação e acesso direto. A
migração necessária é
`supabase/migrations/202611230002_create_action_plans.sql`.
