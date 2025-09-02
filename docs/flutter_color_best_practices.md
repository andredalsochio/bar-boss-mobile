# Flutter Color Best Practices

## Depreciação do withOpacity

### ⚠️ Importante: withOpacity está depreciado

A partir do Flutter 3.27, o método `withOpacity()` foi depreciado em favor do novo método `withValues()`.

### ❌ Forma antiga (depreciada):
```dart
Color.red.withOpacity(0.5)
```

### ✅ Forma nova (recomendada):
```dart
Color.red.withValues(alpha: 0.5)
```

## Implementação no Projeto

### Sistema de Cores Dinâmicas

O projeto utiliza a classe `AppColors` refatorada para suportar tema claro e escuro:

```dart
class AppColors {
  // Cores dinâmicas baseadas no tema
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color background(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  
  // Cores com transparência usando withValues
  static Color primaryDark(BuildContext context) => 
    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8);
}
```

### Vantagens da Nova Abordagem

1. **Compatibilidade com Temas**: As cores se adaptam automaticamente ao tema claro/escuro
2. **API Moderna**: Uso do `withValues()` em vez do `withOpacity()` depreciado
3. **Consistência**: Todas as cores seguem o mesmo padrão
4. **Manutenibilidade**: Mudanças de tema centralizadas

### Migração Completa

Todos os widgets e telas foram atualizados para:
- Usar `AppColors.color(context)` em vez de `AppColors.color`
- Remover `const` de widgets que agora dependem do contexto
- Aplicar `withValues(alpha: value)` em vez de `withOpacity(value)`

### Exemplo de Uso

```dart
// Widget que se adapta ao tema
Container(
  color: AppColors.primary(context),
  child: Text(
    'Texto',
    style: TextStyle(
      color: AppColors.textPrimary(context),
    ),
  ),
)

// Cor com transparência
Container(
  color: AppColors.primary(context).withValues(alpha: 0.1),
  // ...
)
```

## Checklist de Migração

- [x] Refatorar classe `AppColors`
- [x] Atualizar widgets principais (`ButtonWidget`, `AppDrawer`, etc.)
- [x] Migrar telas de autenticação
- [ ] Migrar telas de cadastro
- [ ] Migrar telas de eventos
- [ ] Migrar telas de perfil
- [ ] Testar tema claro/escuro em todas as telas

## Referências

- [Flutter 3.27 Release Notes](https://docs.flutter.dev/release/release-notes)
- [Color.withValues Documentation](https://api.flutter.dev/flutter/dart-ui/Color/withValues.html)
- [Material Design Color System](https://m3.material.io/styles/color/system)