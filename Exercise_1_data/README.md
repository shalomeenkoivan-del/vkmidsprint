# Hello World WebApp and Monitoring by Shalomeenko Ivan Andreevich

## Описание проекта
Простой веб-сервер на Python, который отвечает "Hello World!".  
Реализован скрипт мониторинга на Bash с возможностью логирования и автоматическим перезапуском приложения при сбое.  
Мониторинг запускается через systemd как сервис и автоматически стартует при загрузке системы.

## Структура проекта
- `webapp.py` - Python веб-сервер на стандартной библиотеке.
- `monitoring.sh` - Bash-скрипт мониторинга доступности приложения.
- `config.sh` - конфигурационный файл с параметром интервала проверки `N`.
- `monitoring.service` - unit-файл systemd для автозапуска мониторинга.
- `hosts.ini` - файл инвентаря Ansible для локального запуска.
- `playbook.yml` - Ansible playbook для автоматизации установки и запуска мониторинга.

## Установка и запуск

### Запуск вручную (для разработки и тестирования)
1. Запусти веб-сервер:  
python3 webapp.py
2. Запусти мониторинг:  
bash monitoring.sh

Логи мониторинга пишутся в файл `monitoring.log` в корне проекта (рядом со скриптом).

### Автоматический запуск через systemd
1. Скопируй unit-файл:  
sudo cp monitoring.service /etc/systemd/system/
2. Перегрузи daemon systemd:
sudo systemctl daemon-reload
3. Включи и запусти сервис мониторинга:  
sudo systemctl enable monitoring.service
sudo systemctl start monitoring.service
4. Проверь статус сервиса и логи:  
sudo systemctl status monitoring.service
journalctl -u monitoring.service -f

### Автоматизация с помощью Ansible
1. Подготовь `hosts.ini` с содержимым:  
[local]
localhost ansible_connection=local
2. Запусти playbook:  
ansible-playbook -i hosts.ini playbook.yml

Playbook автоматически скопирует файлы, настроит права, установит зависимости и запустит monitoring.service.

## Конфигурация
- Интервал проверки задается в `config.sh` через переменную `N`.
- IP адрес приложения автоматически определяется вызовом `python3 webapp.py ip`
- Порт веб-приложения фиксированный - 8000.

## Проверка работы
- Посети URL: http://localhost:8000/ или `http://<ip_машины>:8000/` - отобразится строка "Hello World!".
- Логи мониторинга доступны в файле `monitoring.log` и в `journalctl` для systemd-сервиса.
- При падении веб-сервера мониторинг автоматически перезапускает его.