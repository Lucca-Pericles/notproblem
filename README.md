# Agile Knowledge — esqueleto Flutter

Base inicial do Agile Knowledge com telas, tema, navegação, componentes
reutilizáveis, autenticação com Supabase, rotas privadas e a estrutura inicial
do banco de dados.

## Telas incluídas

- Dashboard;
- lista de ocorrências;
- registro de novo atraso;
- investigação guiada com 5 Porquês;
- acompanhamento do plano de ação;
- histórico de aprendizados.

## Organização

```text
lib/
├── app/                    # Aplicação e rotas
├── core/
│   ├── constants/          # Espaçamentos e constantes visuais
│   └── theme/              # Cores e tema Material
├── features/
│   ├── dashboard/
│   ├── occurrences/
│   ├── investigations/
│   ├── actions/
│   └── history/
└── shared/widgets/         # Componentes usados por várias telas
```

## Como executar

O ambiente onde o esqueleto foi criado não contém o Flutter SDK, então as
pastas de plataforma não foram geradas. Em um computador com Flutter instalado:

```bash
flutter create .
flutter pub get
Copy-Item config/dev.example.json config/dev.json
flutter run --dart-define-from-file=config/dev.json
```

O comando `flutter create .` adiciona Android, iOS, Web, Windows, macOS e Linux
sem substituir a pasta `lib`.

## Configurar autenticação e banco

1. Crie um projeto gratuito no Supabase.
2. Copie `config/dev.example.json` para `config/dev.json` e preencha a URL e a
   chave publicável do projeto. O arquivo real fica ignorado pelo Git.
3. Execute `supabase/migrations/202611130001_initial_auth.sql` no SQL Editor do
   Supabase ou aplique a migração pela CLI.
4. Inicie o app com `--dart-define-from-file=config/dev.json`.

Para publicar a versão Web, use a mesma estratégia com um arquivo de produção
fora do Git:

```bash
flutter build web --dart-define-from-file=config/prod.json
```

O aplicativo nunca recebe nem armazena hashes de senha. O Supabase Auth faz o
processamento no servidor; o banco público mantém somente o perfil do usuário.
As políticas RLS garantem que cada usuário leia e altere apenas o próprio perfil.

## Fluxo entregue

- cadastro com nome, e-mail e senha validada;
- login, persistência de sessão e logout;
- redirecionamento de rotas privadas para a tela de entrada;
- página inicial personalizada com o nome autenticado;
- credenciais de ambiente fora do código-fonte;
- mensagens de erro sem registrar senha ou outros dados sensíveis.

## Próximos passos sugeridos

1. Criar as entidades de domínio: ocorrência, investigação, resposta, ação e
   aprendizado.
2. Escolher uma solução de estado e injeção de dependência.
3. Implementar repositórios e fontes de dados.
4. Trocar os dados estáticos das páginas por dados reais.
5. Adicionar validação, autenticação e testes por Sprint.
