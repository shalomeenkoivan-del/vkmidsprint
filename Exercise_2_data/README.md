# Автоматизированная Single-инсталляция ClickHouse в Kubernetes by Shalomeenko Ivan Andreevich
Контакты: shalomeenkoivan@gmail.com | +7 951 648-90-72
Задание: Exercise2, VK "Midsprint"

## Описание проекта
Данный проект реализует полностью автоматизированную и параметризованную single (одноподовую) инсталляцию СУБД ClickHouse в локальном кластере Kubernetes. Решение позволяет гибко задавать версию ClickHouse и управлять учетными данными пользователей без прямого редактирования манифестов.

## Реализованные возможности
1. Развертывание ClickHouse в одном Pod через официальный Docker-образ clickhouse/clickhouse-server.
2. Параметризация версии ClickHouse через командную строку — без изменения манифеста.
3. Безопасное управление пользователями и паролями с динамической генерацией конфигурации и хранением данных в Kubernetes Secret.

## Используемые технологии

- Kubernetes (локальный кластер через minikube)
- Docker (в качестве драйвера minikube)
- Bash (автоматизация и интерактивное управление)
- ClickHouse (официальный Docker-образ)
- Kubernetes Secrets (для хранения учетных данных)
- Kubernetes Service (для стабильного доступа к Pod)
- Шаблонизация манифеста через envsubst

## Архитектура решения

### 1. Deployment + Service

- clickhouse-deployment.yaml.tmpl - шаблон Deployment-манифеста с переменной ${clickhouse_version}
- clickhouse-svc.yaml - Service для стабильного внутреннего и внешнего доступа к ClickHouse (порты 8123 HTTP и 9000 native)

### 2. Управление пользователями

- Учетные данные пользователей (логин/пароль) вводятся в интерактивном режиме
- На основе ввода генерируется файл users.xml, соответствующий [формату конфигурации ClickHouse](https://clickhouse.com/docs/en/operations/configuration-files/)
- Этот файл передается в pod через Kubernetes Secret (clickhouse-users-config) и монтируется в директорию /etc/clickhouse-server/users.d/

- Почему Secret, а не ConfigMap? 
- Согласно [лучшим практикам Kubernetes](https://habr.com/ru/companies/beeline_cloud/articles/864222/), чувствительные данные (пароли, токены) должны храниться в Secret, а не в ConfigMap, даже если базовое кодирование (Base64) не является шифрованием.

### 3. Автоматизация через start.sh

- Скрипт start.sh предоставляет интерактивное меню с двумя основными режимами:
1) Добавление пользователей: ввод логинов и паролей с валидацией формата и экранированием XML-символов (<, > и &)
2) Запуск: указание версии ClickHouse, генерация Secret, подстановка версии в шаблон,  применение манифестов

- Скрипт полностью изолирован от манифестов: все параметры передаются динамически.

- Безопасность:
а) пароли не хранятся в открытом виде в коде, ConfigMap или логах
б) все учетные данные передаются через Secret и монтируются как файл в нужную pod

- Использованные ресурсы:
https://clickhouse.com/docs
https://youtu.be/TwyhnBDOHPw?si=VY3-mR3ejwbWbU29
https://habr.com/ru/companies/beeline_cloud/articles/864222/

- Ссылка на публичный репозиторий со всеми файлами:
https://github.com/shalomeenkoivan-del/vkmidsprint/tree/main/Exercise_2_data