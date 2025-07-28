# Caddy Manager

Веб-приложение для управления Caddyfile с красивым интерфейсом на Tabler UI.

## 🚀 Технологии

- **Frontend**: Vanilla JavaScript + Tabler UI
- **Backend**: Go + Gin Framework
- **Интерфейс**: Современный веб-интерфейс с табличным представлением

## 🎯 Возможности

- 📝 Редактирование Caddyfile через удобную таблицу
- 💾 Автоматическое создание бэкапов перед изменениями
- 🔄 Перезапуск Caddy сервера
- 📋 Просмотр и восстановление бэкапов
- 🔍 Проверка статуса портов в реальном времени
- 🔐 Базовая аутентификация
- 📱 Адаптивный дизайн с Tabler UI
- ✅ Валидация синтаксиса перед применением
- 📚 Соответствие официальным стандартам Caddyfile

## Установка

### Требования

- Go 1.21 или выше
- Caddy сервер
- Права на запись в `/etc/caddy/Caddyfile`

### Шаги установки

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd caddy-manager
```

2. Установите зависимости:
```bash
go mod tidy
```

3. Создайте и настройте файл `.env`:
```bash
make setup
# Отредактируйте .env файл под ваши нужды
```

4. Настройте переменные окружения в `.env`:
```env
CADDYFILE_PATH=/etc/caddy/Caddyfile
BACKUP_DIR=./backups
PORT=8000
AUTH_USERNAME=admin
AUTH_PASSWORD=admin123
```

5. Создайте директорию для бэкапов:
```bash
mkdir -p backups
```

6. **Setup sudo permissions (required for production):**
```bash
sudo make setup-sudo
```
Details in [SUDO_SETUP.md](SUDO_SETUP.md)

7. Запустите приложение:
```bash
# Режим разработки
make dev

# Или в фоновом режиме
make start
```

Приложение будет доступно по адресу `http://localhost:8000`

**Важно**: Для доступа к приложению потребуется ввести логин и пароль, указанные в переменных окружения.

### Makefile Commands

- `make setup` - Create `.env` file from example
- `make setup-sudo` - Setup sudo permissions (requires sudo)
- `make build` - Build application
- `make dev` - Run in development mode
- `make start` - Start in background mode
- `make stop` - Stop application
- `make restart` - Restart application
- `make status` - Show application status
- `make logs` - Show logs in real-time
- `make logs-show` - Show all logs
- `make clean` - Clean built files

## Использование

### Основные функции

1. **Редактирование**: Откройте веб-интерфейс и отредактируйте Caddyfile в редакторе с подсветкой синтаксиса
2. **Сохранение**: Нажмите кнопку "Save" для сохранения изменений (автоматически создается бэкап)
3. **Перезапуск**: Нажмите "Restart Caddy" для применения изменений
4. **Бэкапы**: Используйте вкладку "Backups" для просмотра и восстановления предыдущих версий

### API Endpoints

- `GET /api/caddyfile` - Получить содержимое Caddyfile
- `POST /api/caddyfile` - Сохранить Caddyfile
- `POST /api/restart` - Перезапустить Caddy
- `GET /api/backups` - Получить список бэкапов
- `POST /api/backup` - Создать новый бэкап
- `GET /api/backup/:id` - Получить содержимое бэкапа
- `POST /api/restore/:id` - Восстановить бэкап
- `GET /api/check-ports` - Проверить статус всех портов

## 📚 Поддержка стандартов Caddyfile

Приложение полностью соответствует [официальной документации Caddyfile](https://caddyserver.com/docs/caddyfile/concepts) и поддерживает:

### ✅ Поддерживаемые концепции:

- **Глобальные опции** - блок `{ }` в начале файла
- **Сниппеты** - именованные блоки `(name) { }`
- **Блоки сайтов** - основной контент с адресами и директивами
- **Комментарии** - начинаются с `#`
- **Директивы** - `reverse_proxy`, `file_server`, `request_body`, `transport`
- **Поддирективы** - `max_size`, `read_timeout`, `root *`
- **Импорты** - `import` директивы для сниппетов

### 🔧 Парсер Caddyfile:

- Правильно обрабатывает вложенные блоки
- Игнорирует глобальные опции и сниппеты при извлечении доменов
- Корректно извлекает порты из `reverse_proxy` директив
- Поддерживает сложные конфигурации с `request_body` и `transport`

### 📖 Примеры:

В директории `examples/` вы найдете примеры различных конфигураций:

- `complex-caddyfile` - Демонстрирует все поддерживаемые возможности:
  - Глобальные опции
  - Сниппеты для логирования и безопасности
  - Различные типы сайтов (file_server, reverse_proxy)
  - Сложные конфигурации с таймаутами
  - Множественные адреса и поддомены

## Безопасность

⚠️ **Важно**: Приложение требует прав на запись в системные файлы. Рекомендуется:

- Запускать с минимальными необходимыми правами
- **Обязательно настроить AUTH_USERNAME и AUTH_PASSWORD в .env**
- Использовать сложные пароли для продакшена
- Регулярно проверять бэкапы
- Использовать HTTPS в продакшене
- Ограничить доступ к порту только с доверенных IP-адресов

## Разработка

### Структура проекта

```
caddy-manager/
├── main.go              # Основной файл приложения
├── handlers.go          # API обработчики
├── auth.go              # Аутентификация и безопасность
├── go.mod               # Go модули
├── env.example          # Пример конфигурации
├── Makefile             # Management commands
├── SUDO_SETUP.md        # Документация по настройке sudo
├── static/              # Статические файлы
│   └── index.html       # Веб-интерфейс (Vanilla JS + Tabler UI)
├── backups/             # Директория для бэкапов
├── examples/            # Примеры Caddyfile
└── README.md            # Документация
```

### Сборка

```bash
go build -o caddy-manager .
```

### Запуск в продакшене

```bash
./caddy-manager
```

## Лицензия

MIT License 