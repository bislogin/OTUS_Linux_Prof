# Домашнее задание
## Systemd - создание unit-файла


🎯Задание   
1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/default).   
2. Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта (https://gist.github.com/cea2k/1318020).   
3. Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно.   


### Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова   

Для начала создаём файл с конфигурацией для сервиса в директории /etc/default - из неё сервис будет брать необходимые переменные   
```
root@ubuntu:~# cat /etc/default/watchlog
# Configuration file for my watchlog service
# Place it to /etc/default

# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```

Затем создаем /var/log/watchlog.log и пишем туда строки на своё усмотрение,
плюс ключевое слово ‘ALERT’

##### Создадим скрипт:
```
root@ubuntu:~# cat /opt/watchlog.sh
#!/bin/bash

DATE=$(date)

if grep -q "$WORD" "$LOG"; then
    logger "$DATE: I found word, Master!"
else
    exit 0
fi
```

Команда logger отправляет лог в системный журнал.   
Добавим права на запуск файла:   
```
root@ubuntu:~# chmod +x /opt/watchlog.sh
```

##### Создадим юнит для сервиса:
```
root@ubuntu:~# cat /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh 
```

##### Создадим юнит для таймера:
```
root@ubuntu:~# cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnBootSec=5sec
OnUnitActiveSec=30
AccuracySec=1ms
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Затем достаточно только запустить timer:   
```
root@ubuntu:~# systemctl start watchlog.timer
```

И убедиться в результате:   
```
root@ubuntu:~# tail -n 1000 /var/log/syslog  | grep word
2026-08-06T13:43:21.172815+00:00 ubuntu root: Thu Aug  6 01:43:21 PM UTC 2026: I found word, Master!
2026-08-06T13:43:51.180966+00:00 ubuntu root: Thu Aug  6 01:43:51 PM UTC 2026: I found word, Master!
2026-08-06T13:44:21.191811+00:00 ubuntu root: Thu Aug  6 01:44:21 PM UTC 2026: I found word, Master!
2026-08-06T13:44:51.216486+00:00 ubuntu root: Thu Aug  6 01:44:51 PM UTC 2026: I found word, Master!
```


