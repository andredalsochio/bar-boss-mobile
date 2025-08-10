# Bar Boss Mobile

## Descrição

O Bar Boss é um aplicativo móvel desenvolvido em Flutter para gerenciamento de bares. Este projeto implementa a tela de cadastro de estabelecimentos, seguindo o design do Figma.

## Funcionalidades Implementadas

- Tela de cadastro (Passo 1 - Contatos)
  - Formulário com validação de campos
  - Máscaras para CNPJ e telefone
  - Navegação para o próximo passo

## Estrutura do Projeto

O projeto segue a arquitetura MVVM (Model-View-ViewModel) com Provider para gerenciamento de estado:

```
lib/
  ├── models/             # Classes de modelo de dados
  ├── views/              # Telas da aplicação
  │   └── registration/   # Telas de cadastro
  ├── viewmodels/         # Lógica de negócio e estado
  ├── services/           # Serviços (API, banco de dados, etc.)
  ├── utils/              # Utilitários (cores, estilos, validadores)
  ├── widgets/            # Componentes reutilizáveis
  └── main.dart           # Ponto de entrada da aplicação
```

## Tecnologias Utilizadas

- Flutter
- Provider (gerenciamento de estado)
- Mask Text Input Formatter (máscaras para campos de texto)
- Form Field Validator (validação de formulários)

## Como Executar

1. Certifique-se de ter o Flutter instalado em sua máquina
2. Clone este repositório
3. Execute o comando para instalar as dependências:
   ```
   flutter pub get
   ```
4. Execute o aplicativo:
   ```
   flutter run
   ```

## Próximos Passos

- Implementação do Passo 2 (Endereço)
- Implementação do Passo 3 (Informações adicionais)
- Integração com backend
- Testes unitários e de widget

## Design

O design do aplicativo foi baseado no [Figma do projeto Bar Cover](https://www.figma.com/design/Now10EkRmdupVkg2jKrvDi/Projeto-Bar-Cover).