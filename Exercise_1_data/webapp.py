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