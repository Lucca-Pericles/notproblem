# Validação — SYN-18: Consultar e detalhar ocorrências

| Critério | Evidência |
| --- | --- |
| Lista mostra somente ocorrências do usuário | `listMine()` depende exclusivamente de RLS |
| Detalhe por link direto não expõe outra conta | `getById()` usa `maybeSingle()` e trata zero linhas como não encontrada |
| Contexto é editável apenas em análise aberta | UI oculta a ação em concluídas e banco permite UPDATE somente em `context` |

## Validação manual

1. Aplicar `202611170002_restrict_occurrence_updates.sql`.
2. Usuário A cria duas ocorrências e as confere na lista.
3. Usuário B não visualiza as ocorrências de A e recebe “Ocorrência não encontrada” para um id de A.
4. Confirmar que A altera o contexto de ocorrência aberta.
5. Marcar uma ocorrência como `completed` no SQL Editor e confirmar bloqueio na UI e Data API.
6. Confirmar que tentativas de atualizar `title` ou `status` pela Data API falham.
