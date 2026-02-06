# Ubuntu + Xray (Docker)

Готовый репозиторий с Ubuntu контейнером, в котором запускается Xray клиент и настроена прозрачная маршрутизация для сетей `172.64.0.0/24` и `8.47.0.0/24`.

## Требования
- Docker Desktop или Docker Engine
- Docker Compose (плагин `docker compose` или `docker-compose`)

## Быстрый старт
### Windows (PowerShell)
```powershell
./scripts/run.ps1
```

### Linux/macOS
```bash
./scripts/run.sh
```

Скрипт:
- проверяет зависимости
- собирает и запускает контейнер
- выполняет тесты и базовую проверку

## Что настроено
- Xray запускается на Ubuntu в Docker контейнере
- SOCKS inbound: `0.0.0.0:10808` (???????? ? ????? ????? ??????? ?????)
- Transparent inbound (dokodemo-door): `0.0.0.0:12345`
- iptables правила внутри контейнера перенаправляют трафик к сетям `13.107.0.0/16 18.66.0.0/16 20.118.0.0/16 23.35.0.0/16 104.18.0.0/16 142.250.0.0/16 172.64.0.0/16 184.105.0.0/16 188.114.0.0/16` на Xray

## Важно
- Прозрачная маршрутизация применяется только к трафику внутри контейнера.
- Если нужен доступ к SOCKS с хоста, поменяйте `listen` в `xray/config.json` на `0.0.0.0`.

## Управление
Остановить контейнер:
```bash
docker compose down
```

## Настройки
- Версия Xray фиксирована в `docker-compose.yml` и `Dockerfile` (build arg `XRAY_VERSION`).
- CIDR для прозрачной маршрутизации задаются через переменную `XRAY_ROUTE_CIDRS` в `docker-compose.yml`.

## Тесты
Запустить проверки вручную:
```bash
./scripts/test.sh
```
или
```powershell
./scripts/test.ps1
```



