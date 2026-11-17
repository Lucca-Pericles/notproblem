# Validação — SYN-17: Registrar ocorrência de atraso

## Critérios automatizados

| Critério | Evidência |
| --- | --- |
| Nova ocorrência inicia como Registrada | `widget_test.dart`: repositório de teste retorna `OccurrenceStatus.registered` |
| Campos obrigatórios possuem validação | formulário usa `Form` e validadores para título, projeto, data, contexto e impacto |
| Usuário recebe confirmação e abre detalhe | `NewOccurrencePage`: diálogo de sucesso direciona ao detalhe criado |

## Segurança e validação manual

1. Aplicar `202611170001_create_occurrences.sql` após a migração de autenticação.
2. Entrar como usuário A e registrar uma ocorrência; confirmar o status
   **Registrada** e abrir o detalhe pelo diálogo de sucesso.
3. No SQL Editor, conferir que `user_id` é preenchido com o usuário autenticado.
4. Entrar como usuário B e confirmar que a Data API não lista nem permite criar
   uma ocorrência em nome do usuário A.
5. Confirmar que o usuário A não consegue alterar uma ocorrência com status
   `completed` pela Data API.

As políticas RLS ficam no banco; o aplicativo não envia `user_id` nem usa uma
chave com privilégios administrativos.
