# SYN-22 — Acompanhar status e resultado da ação

## Fluxo entregue

1. Conclua a investigação e abra a ação planejada.
2. Atualize o estado para **Não iniciada**, **Em andamento**, **Concluída** ou
   **Cancelada**.
3. Registre observações durante a execução; cada entrada permanece na linha do
   tempo.
4. Compare o resultado esperado com o resultado observado.
5. Ao concluir, classifique como **Funcionou**, **Funcionou parcialmente** ou
   **Não funcionou**.

## Critérios verificados

- O acompanhamento é criado somente para planos aprovados (`planned`).
- Uma ação concluída exige resultado observado e classificação.
- Estados diferentes de concluída não armazenam classificação.
- O resultado observado pode ser registrado antes da conclusão como rascunho.
- Observações são cronológicas e não podem ser editadas nem excluídas pela
  aplicação.
- A interface informa que a comparação avalia uma hipótese e não comprova
  causalidade.
- Plano, acompanhamento e observações permanecem vinculados ao mesmo usuário e
  ocorrência por chaves estrangeiras compostas.
- RLS limita leitura e escrita ao proprietário autenticado.

## Verificação automatizada

```powershell
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

A suíte cobre os quatro estados, as três classificações, validação da
conclusão, comparação dos resultados e múltiplas observações. A migração
necessária é
`supabase/migrations/202611240002_create_action_follow_ups.sql`.
