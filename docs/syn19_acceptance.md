# SYN-19 — Análise guiada dos 5 Porquês

## Fluxo entregue

1. Abra uma ocorrência e selecione **Abrir análise dos 5 Porquês**.
2. Leia a finalidade e a limitação do método.
3. Responda cada pergunta e selecione **Salvar e continuar**.
4. Saia e abra novamente a ocorrência para conferir a retomada automática.
5. Após a quinta resposta, revise e edite o conjunto completo.
6. Selecione **Finalizar análise** e confira o resumo somente leitura.

## Critérios verificados

- A introdução explica que o método levanta uma hipótese e não comprova a
  causa sem evidências.
- Somente uma pergunta é editada por vez, e nenhuma resposta vazia avança.
- A pergunta seguinte inclui a resposta anterior como contexto.
- Cada resposta é persistida separadamente no Supabase; a primeira resposta
  ausente define o ponto de retomada.
- As cinco respostas podem ser editadas na revisão antes da finalização.
- Depois da finalização, respostas e contexto da ocorrência ficam somente para
  leitura; o caso permanece **Em investigação** até a etapa posterior de plano
  de ação.
- O MVP apresenta somente o método dos 5 Porquês.
- As políticas RLS permitem consultar e alterar somente investigações da conta
  autenticada e bloqueiam alterações após a finalização.

## Verificação automatizada

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Os testes cobrem encadeamento, obrigatoriedade, persistência simulada, retomada,
revisão e finalização. A migração necessária é
`supabase/migrations/202611230001_create_five_why_investigations.sql`.
