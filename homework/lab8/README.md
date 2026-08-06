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

### Установить spawn-fcgi и создать unit-файл (spawn-fcgi.sevice) с помощью переделки init-скрипта   

Устанавливаем spawn-fcgi и необходимые для него пакеты:   
```
root@ubuntu:~# apt install spawn-fcgi php php-cgi php-cli  apache2 libapache2-mod-fcgid -y
```

Сам Init скрипт, который будем переписывать, можно найти здесь: https://gist.github.com/cea2k/1318020    

Но перед этим необходимо создать файл с настройками для будущего сервиса в файле /etc/spawn-fcgi/fcgi.conf.   
Он должен получится следующего вида:   
```
root@ubuntu:~# cat /etc/spawn-fcgi/fcgi.conf
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"
```
##### А сам юнит-файл будет примерно следующего вида:   
```
root@ubuntu:~# cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Убеждаемся, что все успешно работает:   
```
root@ubuntu:~# systemctl start spawn-fcgi
root@ubuntu:~# systemctl status spawn-fcgi
в—Џ spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Thu 2026-08-06 13:57:36 UTC; 5s ago
   Main PID: 31029 (php-cgi)
      Tasks: 33 (limit: 4600)
     Memory: 14.5M (peak: 14.6M)
        CPU: 111ms
     CGroup: /system.slice/spawn-fcgi.service
             в”њв”Ђ31029 /usr/bin/php-cgi
             в”њв”Ђ31030 /usr/bin/php-cgi
             в”њв”Ђ31031 /usr/bin/php-cgi
             в”њв”Ђ31032 /usr/bin/php-cgi
             в”њв”Ђ31033 /usr/bin/php-cgi
             в”њв”Ђ31034 /usr/bin/php-cgi
             в”њв”Ђ31035 /usr/bin/php-cgi
             в”њв”Ђ31036 /usr/bin/php-cgi
             в”њв”Ђ31037 /usr/bin/php-cgi
             в”њв”Ђ31038 /usr/bin/php-cgi
             в”њв”Ђ31039 /usr/bin/php-cgi
             в”њв”Ђ31040 /usr/bin/php-cgi
             в”њв”Ђ31041 /usr/bin/php-cgi
             в”њв”Ђ31042 /usr/bin/php-cgi
             в”њв”Ђ31043 /usr/bin/php-cgi
             в”њв”Ђ31044 /usr/bin/php-cgi
             в”њв”Ђ31045 /usr/bin/php-cgi
             в”њв”Ђ31046 /usr/bin/php-cgi
             в”њв”Ђ31047 /usr/bin/php-cgi
             в”њв”Ђ31048 /usr/bin/php-cgi
             в”њв”Ђ31049 /usr/bin/php-cgi
             в”њв”Ђ31050 /usr/bin/php-cgi
             в”њв”Ђ31051 /usr/bin/php-cgi
             в”њв”Ђ31052 /usr/bin/php-cgi
             в”њв”Ђ31053 /usr/bin/php-cgi
             в”њв”Ђ31054 /usr/bin/php-cgi
             в”њв”Ђ31055 /usr/bin/php-cgi
             в”њв”Ђ31056 /usr/bin/php-cgi
             в”њв”Ђ31057 /usr/bin/php-cgi
             в”њв”Ђ31058 /usr/bin/php-cgi
             в”њв”Ђ31059 /usr/bin/php-cgi
             в”њв”Ђ31060 /usr/bin/php-cgi
             в””в”Ђ31061 /usr/bin/php-cgi

Aug 06 13:57:36 ubuntu systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by Otus.

```

### Доработать unit-файл Nginx (nginx.service) для запуска нескольких инстансов сервера с разными конфигурационными файлами одновременно   

Установим Nginx из стандартного репозитория:   

```
root@ubuntu:~# apt install nginx -y
```

Для запуска нескольких экземпляров сервиса модифицируем исходный service для использования различной конфигурации, а также PID-файлов. Для этого создадим новый Unit для работы с шаблонами (/etc/systemd/system/nginx@.service):   

```
root@ubuntu:~# cat /etc/systemd/system/nginx@.service
root@ubuntu:~# cat  /etc/systemd/system/nginx@.service 
# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on; pid /run/nginx-%I.pid;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on; pid /run/nginx-%I.pid;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on; pid /run/nginx-%I.pid;' -s reload
ExecStop=-/bin/kill -s QUIT $MAINPID
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

Далее необходимо создать два файла конфигурации (/etc/nginx/nginx-first.conf, /etc/nginx/nginx-second.conf). Их можно сформировать из стандартного конфига /etc/nginx/nginx.conf, с разделением по портам:   

```
http {
…
	server {
		listen 9001;
	}
    #include /etc/nginx/sites-enabled/*;
    access_log /var/log/nginx/access-first.log;
    error_log /var/log/nginx/error-first.log;
….
}
```

Этого достаточно для успешного запуска сервисов.
##### Проверим работу:   

```
root@ubuntu:~# systemctl daemon-reload
root@ubuntu:~# systemctl start nginx@first
root@ubuntu:~# systemctl start nginx@second
```

```
root@ubuntu:~# systemctl status nginx@first nginx@second
в—Џ nginx@first.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Thu 2026-08-06 14:23:20 UTC; 15s ago
       Docs: man:nginx(8)
    Process: 32097 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-first.conf -q -g daemon on; master_process on; pid /run/nginx-first.pid; (code=exited, status=0/SUCCESS)
    Process: 32099 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on; pid /run/nginx-first.pid; (code=exited, status=0/SUCCESS)
   Main PID: 32100 (nginx)
      Tasks: 3 (limit: 4600)
     Memory: 2.4M (peak: 2.7M)
        CPU: 26ms
     CGroup: /system.slice/system-nginx.slice/nginx@first.service
             в”њв”Ђ32100 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on; pid /run/nginx-first.pid;"
             в”њв”Ђ32101 "nginx: worker process"
             в””в”Ђ32102 "nginx: worker process"

Aug 06 14:23:20 ubuntu systemd[1]: Starting nginx@first.service - A high performance web server and a reverse proxy server...
Aug 06 14:23:20 ubuntu systemd[1]: Started nginx@first.service - A high performance web server and a reverse proxy server.

в—Џ nginx@second.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/etc/systemd/system/nginx@.service; disabled; preset: enabled)
     Active: active (running) since Thu 2026-08-06 14:23:26 UTC; 9s ago
       Docs: man:nginx(8)
    Process: 32112 ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-second.conf -q -g daemon on; master_process on; pid /run/nginx-second.pid; (code=exited, status=0/SUCCESS)
    Process: 32113 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; pid /run/nginx-second.pid; (code=exited, status=0/SUCCESS)
   Main PID: 32115 (nginx)
      Tasks: 3 (limit: 4600)
     Memory: 2.3M (peak: 2.5M)
        CPU: 25ms
     CGroup: /system.slice/system-nginx.slice/nginx@second.service
             в”њв”Ђ32115 "nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; pid /run/nginx-second.pid;"
             в”њв”Ђ32116 "nginx: worker process"
             в””в”Ђ32117 "nginx: worker process"

Aug 06 14:23:25 ubuntu systemd[1]: Starting nginx@second.service - A high performance web server and a reverse proxy server...
Aug 06 14:23:26 ubuntu systemd[1]: Started nginx@second.service - A high performance web server and a reverse proxy server.
```

Проверить можно несколькими способами, например, посмотреть, какие порты слушаются:   
```
root@ubuntu:~# ss -tnulp | grep nginx
tcp   LISTEN 0      511          0.0.0.0:9002      0.0.0.0:*    users:(("nginx",pid=32117,fd=6),("nginx",pid=32116,fd=6),("nginx",pid=32115,fd=6))
tcp   LISTEN 0      511          0.0.0.0:9001      0.0.0.0:*    users:(("nginx",pid=32102,fd=6),("nginx",pid=32101,fd=6),("nginx",pid=32100,fd=6))
```

Или просмотреть список процессов:   
```
root@ubuntu:~# ps afx | grep nginx
  32821 pts/1    S+     0:00                          \_ grep --color=auto nginx
  32100 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on; pid /run/nginx-first.pid;
  32101 ?        S      0:00  \_ nginx: worker process
  32102 ?        S      0:00  \_ nginx: worker process
  32115 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on; pid /run/nginx-second.pid;
  32116 ?        S      0:00  \_ nginx: worker process
  32117 ?        S      0:00  \_ nginx: worker process
```





