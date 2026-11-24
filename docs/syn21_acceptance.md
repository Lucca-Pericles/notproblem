# SYN-21 — Revisar e concluir a investigação

## Fluxo entregue

1. Conclua os 5 Porquês e salve a causa provável e o plano de ação.
2. Selecione **Revisar investigação**.
3. Confira ocorrência, cinco respostas, hipótese e plano no mesmo resumo.
4. Use os atalhos para corrigir contexto, respostas ou plano.
5. Selecione **Concluir investigação**.
6. O sistema altera a ocorrência para **Ação planejada** e abre o
   acompanhamento da ação.

## Critérios verificados

- O resumo reúne todos os dados exigidos pelo card.
- A conclusão permanece desabilitada enquanto uma etapa obrigatória estiver
  ausente.
- Contexto, cinco respostas e plano podem ser editados durante a revisão.
- Após a conclusão, essas etapas ficam somente para consulta.
- A transição do plano para `planned` e da ocorrência para `action_planned`
  ocorre na mesma função transacional do banco.
- A função valida proprietário, estado da ocorrência, cinco respostas, campos
  do plano e prazo antes de concluir.
- RLS mantém leitura e edição limitadas ao usuário autenticado proprietário.
- Planos anteriores que já estavam em `planned` permanecem concluídos.

## Verificação automatizada

```powershell
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub
```

A suíte cobre o resumo integral, a navegação para correções, o bloqueio por
dados ausentes, a conclusão e o redirecionamento. A migração necessária é
`supabase/migrations/202611240001_review_and_conclude_investigations.sql`.
