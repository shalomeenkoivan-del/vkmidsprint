Шаломеенко Иван Андреевич
shalomeenkoivan@gmail.com
+79516489072
Exercise1, VK "Midsprint"

1. Создаю простое веб-приложение, которое возвращает "Hello World!":
touch webapp.py

Для файла конфигурации, где будет находиться основной параметр - N (интервал проверки), создаю config.sh (чтобы N можно было задавать и менять динамически):
touch config.sh

Содержание файла config.sh:
#!/usr/bin/env bash

# Частота проверки:
N=10
# Экспортирую переменную:
export N

Пишу следующий код в webapp.py:
# Импорт модуля socket для определения IP-адреса:
import socket
# Импорт компонентов HTTP-сервера из стандартной библиотеки Python:
# - BaseHTTPRequestHandler — базовый класс для обработки HTTP-запросов
# - HTTPServer — класс, нужный для реализации простого HTTP-сервер
from http.server import BaseHTTPRequestHandler, HTTPServer
# Импорт модуля для работы с аргументами командной строки:
import sys

# Функция, который будет определять IP-адрес, с которого будет запускаться сервер, и по которому мы будем "стучаться", который будет возвращать IPv4-адрес или localhost при ошибке:
def get_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
        return ip
    except Exception:
        return "127.0.0.1"

# Создаю класс, наследуемый от BaseHTTPRequestHandler с "родительским" методом для обработки HTTP-запросов:
class HelloWorldHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain") # Говорю браузеру, что будет обычный текст
        self.end_headers()
        self.wfile.write(b"Hello World!") # Передаю этот самый текст (а именно: "Hello World!") в браузер

# Запуск самого сервера:
if __name__ == "__main__":
# Добавляю возможность запуска приложения с аргументом "ip" (python3 webbapp.py ip), чтобы просто вывести IP и выйти (чтобы далее использовать этот IP при проверке):
    if len(sys.argv) > 1 and sys.argv[1] == "ip":
        print(get_ip())
    else:
# Если запускаем как обычно (python3 webapp.py):
        local_ip = get_ip() # определяем локальный IP для вывода
# Запускаем наш сервер всех сетевых интерфейсах (0.0.0.0), а не только на localhost (чтобы до него можно было достучаться извне):
        server = HTTPServer(("0.0.0.0", 8000), HelloWorldHandler)
# Показываем для удобства по какому URL и порту запущен сервер:
        print(f"Server started at http://{local_ip}:8000")
# Запускаем бесконечный цикл обслуживания запросов:
        server.serve_forever()

Запускаю сервер:
python3 webapp.py

Проверяю в браузере (альтернативно можно через curl):
http://192.168.0.173:8000/

Содержимое веб-страницы:
Hello World!

2. Создадим скрипт мониторинга со следующим фукнкционалом: проверка доступности приложения; логирование результатов проверки; перезапуск приложения, в случае его недоступности:
touch monitoring.sh
chmod +x monitoring.sh

Пишу monitoring.sh:
#!/usr/bin/env bash

# Импортируем данные из конфиг-файла, в частности переменную N:
source config.sh

# Скрипт мониторинга только что написанного веб-приложения с логированием в корневой директории скрипта

# Записываю в переменную, где находится файл самого приложения:
webapp_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/webapp.py"
# Объявляю переменную, в которой будет содержаться название логфайла и куда будем его сохранять (для удобства будем создавать его в той же директории где находится сам скрипт monitoring.sh, то есть если даже будем запускать его из другой директории - сохранять будем в том же месте, где и все файлы):
logfile="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/monitoring.log"
# Переменная со статусом работы приложения, значение которой будем записыват в лог:
status_log=0
# Получаю ip, по которому будем проверять доступность приложения (не localhost, чтобы проверять явно извне):
ip=$(python3 "$webapp_path" ip)

# Проверка, если ip не получен:
if [[ -z "$ip" ]]; then
    echo "Error! Run webapp.py or check your network!"
    exit 1
fi

# Формируем из протокола, ip и порта url, по которому будет доступно наше приложение:
app_url="http://$ip:8000"

# Функция, которая будет проверять работает наш сервер или нет (в качестве аргумента передаю наш url) и выведет только число — HTTP-код ответа от сервера (200, если сервер жив):
check()
{
curl -s -o /dev/null -w "%{http_code}" "$1" 
}

# Функция для запуска приложения в фоне:
start_webapp() 
{
# Убиваем старые процессы на всякий случай:
pkill -f "python3.*webapp.py" 2>/dev/null
sleep 1
# Запускаем приложение в фоне:
python3 "$webapp_path" > /dev/null 2>&1 &  
}

# Если при запуске скрипта мониторинга сервер ещё не работает - запускаем его сразу:
if ! curl -s --connect-timeout 2 "$app_url" >/dev/null; then
start_webapp
sleep 3
fi

# Основной цикл мониторинга:
while true; do
http_code=$(check "$app_url")
# Определяю текстовый статус (переменная status_log, которую объявлял ранее) на основе полученного кода:
if [[ "$http_code" == 200 ]]; then
status_log="OK"
elif [[ "$http_code" == "000" ]]; then
status_log="FAILED (SERVER IS DOWN)"
# Перезапускаем сервер:
start_webapp
sleep 5
else
status_log="FAILED (HTTP ERROR $http_code)"
fi
# Записываем отформатированные текущие дату и время в переменную:
timedate=$(date +"%Y-%m-%d %H:%M:%S")
# Дописываем новую строку в конец файла:
echo "$timedate STATUS: $status_log" >> "$logfile"
# Устанавливаю задержку в N секунд, чтобы осуществлять проверку с данной периодичностью:
sleep "$N"
done

Проверяю скрипт линтером:
shellcheck monitoring.sh config.sh

Вывод:
<пустая строка> (значит все ОК)

Проверяю работу скрипта:
bash monitoring.sh

Проверяю созданный при запуске скрипта файл monitoring.log:
2025-11-25 22:36:45 STATUS: FAILED (SERVER IS DOWN)
2025-11-25 22:36:55 STATUS: FAILED (SERVER IS DOWN)
2025-11-25 22:37:05 STATUS: FAILED (SERVER IS DOWN)
2025-11-25 22:37:15 STATUS: OK
2025-11-25 22:37:25 STATUS: OK
2025-11-25 22:37:35 STATUS: OK
2025-11-25 23:17:41 STATUS: OK
2025-11-25 23:17:57 STATUS: FAILED (SERVER IS DOWN)
2025-11-25 23:18:07 STATUS: OK
2025-11-25 23:18:18 STATUS: OK

3. Далее для того чтобы скрипт мониторинга запускался автоматически при старте системы и работал в фоне, создам unit-файл "monitoring.service" для systemd:
sudo nano /etc/systemd/system/monitoring.service

Пишу простой unit-файл (комментарии пишу на английском, так как Linux не поддерживает русскую раскладку, а код webapp.py и скрипт monitoring.sh я писал в Visual Studio на Windows, открыв через монтирование общей папки DO6_CICD.ID_356283-1):
[Unit]
# Short description of the service:
Description=Web application monitoring with automatic restart on failure
# Start only after the network is available:
After=network.target

[Service]
# Service type:
Type=simple
# Working directory where webapp.py and monitoring.sh are located:
WorkingDirectory=/media/sf_DO6_CICD.ID_356283-1/src/VK/
# Command to start:
ExecStart=/usr/bin/env bash /media/sf_DO6_CICD.ID_356283-1/src/VK/monitoring.sh
# Restart settings:
Restart=always
RestartSec=5
# Send stdout and stderr to the systemd journal (journalctl):
StandardOutput=journal
StandardError=journal

[Install]
# Enable the service at boot in multi-user mode:
WantedBy=multi-user.target

Далее скопирую этот файл в корень проекта, для того чтобы прикрепить в конце задания ссылкой вместе с остальными файлами:
cp /etc/systemd/system/monitoring.service $(pwd)

Перегружаю демон systemd, включаю автозапуск и запускаю сервис:
sudo systemctl daemon-reload
sudo systemctl enable monitoring.service
sudo systemctl start monitoring.service

Проверяю, что всё работает (статус сервиса):
sudo systemctl status monitoring.service

Посмотрим отображаются ли логи в реальном времени:
journalctl -u monitoring.service -f

Для финальной проверки перезагружаю виртуальную машину:
sudo reboot

Теперь проверяю статус:
sudo systemctl status monitoring.service

И смотрю лог (для разнообразия по созданному файлу):
tail /media/sf_DO6_CICD.ID_356283-1/src/VK/monitoring.log

4. Далее необходимо автоматизировать процесс установки и обновления скрипта мониторинга, для выполнения этой задачи можно было бы написать так же bash-скрипт, но для разнообразия хочу использовать Ansible.

Для начала создадим файл-inventory для Ansible:
touch hosts.ini

Так как по хаданию мы все делаем на одном хосте (локальной машине), то пропишем в файлеinventory для Ansible, чтобы он просто запускал команды напрямую:
[local]
localhost ansible_connection=local

Теперь напишем playbook для нашего проекта с веб-приложением и мониторингом, где webapp.py просто копируется, а monitoring.sh разворачивается как systemd-сервис:
touch playbook.yml

Содержание playbook.yml:
- name: Deploy web application with auto-restart monitoring
  hosts: all
  become: yes

  vars:
    project_dir: /opt/webapp_project

  tasks:
    - name: Create project directory
      file:
        path: "{{ project_dir }}"
        state: directory
        mode: '0755'

    - name: Copy web application (webapp.py)
      copy:
        src: webapp.py
        dest: "{{ project_dir }}/webapp.py"
        mode: '0755'

    - name: Copy monitoring script (monitoring.sh)
      copy:
        src: monitoring.sh
        dest: "{{ project_dir }}/monitoring.sh"
        mode: '0755'

    - name: Copy configuration file (config.sh)
      copy:
        src: config.sh
        dest: "{{ project_dir }}/config.sh"
        mode: '0644'

    - name: Install systemd service unit
      copy:
        src: monitoring.service
        dest: /etc/systemd/system/monitoring.service
        mode: '0644'

    - name: Reload systemd and start monitoring service
      systemd:
        name: monitoring.service
        daemon_reload: yes
        enabled: yes
        state: started

Чтобы остановить и очистить текущий мониторинг и проверить запуск через Ansible (что все работает):
sudo systemctl stop monitoring.service (остановим текущий systemd-сервис мониторинга)
sudo systemctl disable monitoring.service (отключим автозапуск сервиса)
pkill -f "python3.*webapp.py" (убьем фоновые процессы webapp.py на всякий случай)
sudo systemctl daemon-reload (перезагрузим демон тоже на всякий случай)
Так же удаляю созданный в корне проекта логфайл.

Запускаем Ansible:
ansible-playbook -i hosts.ini playbook.yml

Перезапустим машину:
sudo reboot

Проверяем еще раз статус сервиса:
systemctl status monitoring.service

Проверяем лог monitoring.log и что файлы скопировались в /opt:
ls -l /opt/webapp_project/

Проверим так же веб:
curl localhost:8000

Вывод:
Hello World!

Итог: все работает, а значит можно писать README-файл с описанием технического решения:
touch README.md

Напишем с markdown:
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

Теперь все данные файлы скопирую в одну папку и закидываю на публичный репозиторий GitHub, для того чтобы была возможность их проверить:
https://github.com/shalomeenkoivan-del/vkmidsprint