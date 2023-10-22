#!/bin/bash
    check=$(ls -1 *.tar.gz)
    # Проверить наличие файлов
    if [ -n "$check" ]; then
    if [ $# -eq 0 ]; then
        # Запуск с графическим интерфейсом (Zenity)
        zenity --info --text "Программа установки 1с сервера на ОС Astra Linux. Графический интерфейс. \nДля просмотра параметров запустите с флагом -h или --help"
        passwd=$(zenity --forms --title="Пароль для администратора" \
                --text="Введите пароль администратора" \
                --add-password="Пароль")
        else
            # Определение длинных опций и коротких опций
            OPTIONS=p:h
            LONGOPTIONS=password:,help

            # Парсим строчку на аругменты
            PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")

            # Проверяем на ошибку
            if [ $? -ne 0 ]; then
            exit 1
            fi
            #сообщение приветствия
            echo Вы используете терминальный режим. Для запуска графического запустите скрипт без параметров.
            # Оцениваем параметры строки
            eval set -- "$PARSED"
            # Устанавливаем параметры для
            help="
Скрипт необходимо запускать находясь в папке с архивом сервера 1с.
Помощь по необходимым параметрам для корректной работы программы:
-p|--password указывает пароль администратора локального ( sudo )" 
            passwd=""  
            # Перебраем аргументы командной строки
            while true; do
            case "$1" in
                -p|--password)
                passwd="$2"
                shift 2
                ;;
                -h|--help)
                echo "$help"
                exit 1
                ;;                                    
                --)
                shift
                break
                ;;
                *)
                echo "Invalid option: $1"
                exit 1
                ;;
            esac
            done
        fi
    # распаковка архива 1с
    tar -xzf *.tar.gz
    # установка распакованных файлов сервера 1с
    echo $passwd | sudo -S dpkg -i 1c-enterprise*common*.deb
    echo $passwd | sudo -S dpkg -i 1c-enterprise*server*.deb
    echo $passwd | sudo -S dpkg -i 1c-enterprise*ws*.deb
    echo $passwd | sudo -S dpkg -i 1c-enterprise*common-nls*.deb
    echo $passwd | sudo -S dpkg -i 1c-enterprise*server-nls*.deb
    echo $passwd | sudo -S dpkg -i 1c-enterprise*ws-nls*.deb
    # записываем перменную версию установленного сервера 1с , если он в 1 числе
    path=/opt/1cv8/x86_64/
    version=$(ls $path)
    # создаем сервис для 1с для автоматического запуска вместе с серверов службы 1с
    echo $passwd | sudo -S cp $path/$version/srv1cv83 /etc/init.d/
    echo $passwd | sudo -S cp $path/$version/srv1cv83.conf /etc/default/srv1cv83
    # Указываем путь к файлу и строкам для замены.Чтобы ragent 1c стартовал от имени пользователя usr1cv8
    file="/etc/init.d/srv1cv83"
    old_line='su -s \/bin\/bash  - "$SRV1CV8_USER" -c "KRB5_KTNAME=\\"$SRV1CV8_KEYTAB\\" $cmd2run"'
    new_line='start-stop-daemon --start --chuid "$SRV1CV8_USER" --oknodo --pidfile "$SRV1CV8_PIDFILE" --start --exec \/usr\/bin\/env KRB5_KTNAME=\\"$SRV1CV8_KEYTAB\\" "$SRV1CV8_BINDIR\/ragent" -- "-daemon"'
    #Заменяем строку в файле с помощью sed
    echo $passwd | sudo -S sed -i "s|$old_line|$new_line|g" "$file"
    # обновляем наши конфиги в сервисе
    echo $passwd | sudo -S update-rc.d srv1cv83 defaults
    # запускаем 1с сервер
    echo $passwd | sudo -S service srv1cv83 start
    echo $passwd | sudo -S service srv1cv83 status
    echo "Сервер 1с версии $version успешно запущен и добавлен в автозагрузку"
else
        echo "Ошибка: Файлы .tar.gz не найдены."
        exit 1
    fi