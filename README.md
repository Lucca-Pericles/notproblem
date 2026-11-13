# Agile Knowledge — esqueleto Flutter

Estrutura visual inicial do Agile Knowledge. O projeto contém telas estáticas,
tema, navegação e componentes reutilizáveis, sem back-end, autenticação,
persistência ou regras de negócio.

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
flutter run
```

O comando `flutter create .` adiciona Android, iOS, Web, Windows, macOS e Linux
sem substituir a pasta `lib`.

## Próximos passos sugeridos

1. Criar as entidades de domínio: ocorrência, investigação, resposta, ação e
   aprendizado.
2. Escolher uma solução de estado e injeção de dependência.
3. Implementar repositórios e fontes de dados.
4. Trocar os dados estáticos das páginas por dados reais.
5. Adicionar validação, autenticação e testes por Sprint.
