#!/usr/bin/env bash

# Инициализация переменной, в которую будет передаваться аргумент - версия:
clickhouse_version=latest

# Объявление массив для хранения данных пользователей (пар логин + пароль):
declare -a USERS

# Функция, которая будет проверять, что передан именно 1 аргумент (можно было продолжить с проверками, но я решил на этом не зацикливаться):
check()
{
if [[ $# -ne 1 ]]; then
echo "Enter 'bash start.sh <correct_clickhouse_version> to run"
exit 1
fi
}

# Панель управления с подсказками по использованию программы:
help()
{
echo "How to run: $0"
echo "Mode selection:"
echo "  1 - add users and passwords"
echo "  2 - set version and start"
echo "  3 - exit"
}

# Функция, которя будет построчно принимать логины и пароли пользователей введенные с клавиатуры (значения "парсятся" из ввода с stdin и сохраняются в массив):
add_users_and_passwords()
{
# Небольшая панель управления с подсказками:
echo "Add users and passwords:"
echo "Controls: <0> to return to main menu, <Enter> to save current string"
echo "Format: user password"
echo "Example: admin mypass"

# Бесконечный цикл ввода с клавиатуры до тех пор, пока пользователь не нажмёт "0" для вовзрата в главное меню:
while true; do
read -p "> " input
   
if [[ "$input" == "0" ]]; then
echo "Users saved."
break
fi
   
# Парсим user, извлекая первое слово из введенной пары с помощью разделения по проблема awk:
username=$(echo "$input" | awk '{print $1}')
# Парсим password, извлекая второе слово из введенной пары с помощью разделения по проблема awk:
password=$(echo "$input" | awk '{print $2}')

# Проверяем, что обе переменные непустые:
if [[ -n "$username" && -n "$password" ]]; then
  # Если значение не путо, проверяем соответствие имени пользователя требованиям ClickHouse:
  if [[ ! "$username" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "  Invalid username! Must match ^[a-zA-Z_][a-zA-Z0-9_]*$"
    continue
  fi
  # Добавляем пару в наш массив:
  USERS+=("$username:$password")
  echo "  Added: $username"
else
echo "  Invalid format! Use: user password"
fi
done
}

# Функция, реализующая второй пункт меню - запуск с указанной версией:
start_with_setted_version()
{
# Вызываем првоерку, что передан ровно один аргумент (версия):
check "$@"
# Теперь, когда точно знаем, что аргумент существует в единственном числе записываем значение версии в переменную и экспортируем (для доступа извне):
export clickhouse_version="$1"

# Удаляем старый Secret, если существует (во избежание возможных конфликтов):
kubectl delete secret clickhouse-users-config --ignore-not-found >/dev/null 2>&1

# Генерируем YAML-файл Secret с динамическим содержимым users.xml:
{
  cat << EOF
apiVersion: v1
kind: Secret
metadata:
  name: clickhouse-users-config
type: Opaque
stringData:
  users.xml: |
    <yandex>
        <users>
EOF

# Пробегаемся циклом "for" по нашим парам из массива и создаем XML-блоки для каждого пользователя:
for user_pass in "${USERS[@]}"; do
# Извлекаем логин и пароль из строк:
username="${user_pass%%:*}"
password="${user_pass#*:}"

# Экранируем спецсимволы в пароле для корректного XML:
password="${password//&/&amp;}"
password="${password//</<}"
password="${password//>/>}"

# Выводим XML-блок пользователя:
      cat << EOF
            <${username}>
                <password>${password}</password>
                <profile>default</profile>
                <networks>
                    <ip>::/0</ip>
                </networks>
            </${username}>
EOF
done
# Закрываем корневые теги XML:
  cat << EOF
        </users>
    </yandex>
EOF
} > clickhouse-users-config.yaml  # сохраняем в файл

# Сначала применяем Secret - он станет доступен для монтирования в Pod:
kubectl apply -f clickhouse-users-config.yaml

# Вызываю небьльшую искусственную задержку, чтобы Secret успел точно создаться до применения Deployment-манифеста:
sleep 1

# Подставляем значение переменной clickhouse_version в шаблон Deployment-манифеста (envsubst заменяет ${clickhouse_version} на реальное значение) и перезаписываем Deployment-манифест:
envsubst < clickhouse-deployment.yaml.tmpl > clickhouse-deployment.yaml

# Применяем итоговый Deployment-манфиест:
kubectl apply -f clickhouse-deployment.yaml

# Выводим информацию об успешном завершении:
echo "Deployment completed for version $clickhouse_version"
echo "Users configured: ${USERS[*]}"
}

# Основной бесконечный цикл с бесклавишным меню (пока пользователь не выберет "3" для выхода):
while true; do
clear # очистка экрана для удобства
help # подсказка
echo -n "Select option (1/2/3): "
read -n1 -s mode
echo  # перевод строки

# Обработка выбора режима пользователем:
case $mode in
    1) add_users_and_passwords ;; # добавление пользователей
    2)
      read -p "Enter ClickHouse version (e.g. 25.10): " version # запрашиваем версию у пользователя (например, 25.10)
      start_with_setted_version "$version" # запускаем развертывание с этой версией
      read -p "Press <Enter> to return to menu..." ;;
    3) echo "Exit"; exit 0 ;; # программа успешно отработала, выход с кодом "0"
    0) continue ;;  # возврат в главное меню 
    *) echo "Invalid input"; sleep 1 ;; # обработка некорректного ввода
esac
done

