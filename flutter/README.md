# Flutter каркас — AI-обвязка для Claude Code

Набор подготовлен под стек: **BLoC 9 + auto_route + slang + RBAC + Hexagonal/Vertical Slice**,
iOS/macOS-first приоритет.

## Что внутри

```
├── CLAUDE.md                 # главный файл — ваша архитектура и соглашения
└── .claude/
    └── skills/               # 21 Agent Skill
        ├── architecture-feature-first/    # от evanca — feature-first структура
        ├── bloc/                          # от evanca — BLoC/Cubit паттерны
        ├── flutter-architecting-apps/     # от Flutter team — layered arch
        ├── flutter-managing-state/        # от Flutter team
        ├── flutter-implementing-navigation-and-routing/
        ├── flutter-localizing-apps/
        ├── flutter-handling-http-and-json/
        ├── flutter-testing-apps/
        ├── flutter-theming-apps/
        ├── flutter-handling-concurrency/
        ├── flutter-caching-data/
        ├── flutter-working-with-databases/
        ├── flutter-building-forms/
        ├── flutter-improving-accessibility/
        ├── flutter-app-architecture/      # от evanca, доп. материал
        ├── effective-dart/
        ├── dart-3-updates/
        ├── mocktail/
        ├── testing/
        ├── code-review/
        └── flutter-errors/
```

## Установка

### Вариант 1 — в конкретный проект (рекомендуется на старте)

Распакуйте содержимое архива в **корень Flutter-проекта**:

```
your_flutter_project/
├── lib/
├── test/
├── pubspec.yaml
├── CLAUDE.md               ← сюда
└── .claude/                ← и сюда
    └── skills/
```

Claude Code при запуске в этой папке автоматически подхватит `CLAUDE.md` и увидит
скиллы в `.claude/skills/`.

### Вариант 2 — глобально для всех Flutter-проектов

Если у вас несколько Flutter-проектов с одинаковым стеком, положите скиллы
в домашнюю директорию:

```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/* ~/.claude/skills/
```

А `CLAUDE.md` всё равно держите per-project — архитектурные решения у разных
проектов могут отличаться.

## Как этим пользоваться

1. **Откройте Claude Code в корне проекта** — он сам загрузит `CLAUDE.md`.
2. **На старте новой задачи** явно просите Claude свериться со скиллом:
   ```
   Read @.claude/skills/bloc/SKILL.md and create AuthCubit for the auth feature
   per our CLAUDE.md architecture.
   ```
3. **Для новой фичи** — двухшаговый промпт:
   ```
   1. Read @.claude/skills/architecture-feature-first/SKILL.md
   2. Scaffold a new feature "catalog" following our CLAUDE.md structure:
      domain/data/application/presentation with a CatalogCubit and RBAC guard
      on the catalog route.
   ```

## Следующие рекомендуемые шаги

1. **Поставить Dart/Flutter MCP Server** — даст Claude Code live-доступ к pub.dev,
   анализатору, hot reload:
   https://docs.flutter.dev/ai/mcp-server

2. **Проверить `CLAUDE.md`** — адаптировать под ваш конкретный проект:
   - список `UserRole` и `Permission` под вашу бизнес-модель
   - список поддерживаемых локалей (сейчас подразумеваются en/ru)
   - специфические правила вашей команды

3. **Сгенерировать первый feature-слайс** через Claude Code — например, auth —
   и убедиться, что структура соответствует `CLAUDE.md`. Это будет эталон
   для остальных фич.

## Источники

- Официальные скиллы Flutter-команды: https://github.com/flutter/skills
- Community-скиллы evanca: https://github.com/evanca/flutter-ai-rules
- Архитектурные рекомендации Flutter: https://docs.flutter.dev/app-architecture
- Flutter AI rules: https://docs.flutter.dev/ai/ai-rules
- Dart/Flutter MCP Server: https://docs.flutter.dev/ai/mcp-server

## Обновление скиллов

Скиллы периодически обновляются в upstream-репах. Чтобы подтянуть свежие версии:

```bash
# официальные
git clone --depth 1 https://github.com/flutter/skills.git /tmp/flutter-skills
cp -r /tmp/flutter-skills/skills/* .claude/skills/
rm -rf /tmp/flutter-skills

# community
git clone --depth 1 https://github.com/evanca/flutter-ai-rules.git /tmp/evanca
cp -r /tmp/evanca/skills/architecture-feature-first .claude/skills/
cp -r /tmp/evanca/skills/bloc .claude/skills/
# ...и остальные нужные вам
rm -rf /tmp/evanca
```

## Лицензии

- Скиллы из `flutter/skills` — под лицензией Flutter project (BSD-style), см.
  LICENSE в репозитории.
- Скиллы из `evanca/flutter-ai-rules` — MIT, см. LICENSE в репозитории.
- Эти лицензионные файлы не включены сюда ради компактности — в production
  положите их рядом, если планируете распространять каркас дальше.
