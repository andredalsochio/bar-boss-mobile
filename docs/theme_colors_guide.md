# Guia de Cores do Tema - Bar Boss Mobile

Este documento descreve as cores implementadas nos temas claro e escuro do aplicativo Bar Boss Mobile.

## Tema Claro

### Cores Principais
- **Cor Primária**: `#D9401F` (Vermelho)
  - Usada em: App Bar, botões principais, elementos de destaque
  - Texto sobre primária: Branco (`#FFFFFF`)

### Background e Superfícies
- **Surface Principal**: `#F5F5F5` (Cinza claro)
  - Fundo principal da aplicação (substitui `background` deprecated)
- **Surface Container (Cards/Banners)**: `#FFFFFF` (Branco)
  - Cards de eventos, banners, formulários
  - Bordas sutis com `Colors.grey.withValues(alpha: 0.2)`
  - Sombra com elevação 4

### Cores Secundárias
- **Secondary**: `#775651` (Marrom acinzentado)
- **Secondary Container**: `#FFdad4` (Rosa claro)

### Bordas e Contornos
- **Outline**: `#857370` (Cinza médio)
- **Outline Variant**: `#D8C2BE` (Bege claro)
- **Surface Container Highest**: `#F3F0F0` (substitui `surfaceVariant` deprecated)

## Tema Escuro

### Cores Principais
- **Cor Primária**: `#FF6B47` (Vermelho vibrante)
  - Versão mais clara e vibrante do vermelho para melhor contraste
  - Texto sobre primária: Preto (`#000000`)

### Background e Superfícies
- **Surface Principal**: `#121212` (Preto suave)
  - Fundo principal escuro (substitui `background` deprecated)
- **Surface Container (Cards)**: `#1E1E1E` (Cinza escuro)
  - Cards com elevação 8 para maior destaque
  - Bordas com `Color(0xFF534341).withValues(alpha: 0.5)`

### App Bar
- **Modo Claro**: Vermelho `#D9401F` com texto branco
- **Modo Escuro**: Cinza escuro `#1E1E1E` com texto claro

## Implementação Técnica

### Localização
As cores estão definidas em:
- `lib/app/core/providers/theme_provider.dart`
- Utiliza `ColorScheme.light()` e `ColorScheme.dark()` do Material 3

### ⚠️ Deprecated Members - NÃO USAR
- `background` / `onBackground` → Use `surface` / `onSurface`
- `surfaceVariant` → Use `surfaceContainerHighest`
- `Color.withOpacity()` → Use `Color.withValues(alpha: value)`

### Componentes Afetados

#### Cards
- **Elevação**: 4 (claro) / 8 (escuro)
- **Bordas**: Sutis com opacidade
- **Sombras**: Configuradas para cada tema

#### Botões
- **Background**: Cor primária do tema
- **Texto**: Contraste adequado (branco/preto)
- **Elevação**: 2 (claro) / 4 (escuro)

#### App Bar
- **Centralizada**: `centerTitle: true`
- **Sem elevação**: `elevation: 0`
- **Cores**: Específicas para cada tema

## Acessibilidade

- Todas as combinações de cores atendem aos padrões de contraste WCAG
- Texto sempre legível sobre os backgrounds escolhidos
- Cores de erro mantidas consistentes entre temas

## Manutenção

Para alterar cores:
1. Edite `theme_provider.dart`
2. **EVITE deprecated members**: use `surface` em vez de `background`, `surfaceContainerHighest` em vez de `surfaceVariant`, e `withValues(alpha:)` em vez de `withOpacity()`
3. Teste em ambos os temas (claro/escuro)
4. Verifique contraste e legibilidade
5. Execute `flutter analyze` para verificar warnings
6. Teste em dispositivos reais quando possível

---

*Última atualização: Janeiro 2025*