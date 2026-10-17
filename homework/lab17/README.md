# Домашнее задание
## Настраиваем центральный сервер для сбора логов

🎯Задание    

1. Поднимаем две машины — web и log.
2. На web поднимаем nginx.
3. Настраиваем центральный лог-сервер на любой системе по выбору:
    * journald;
    * rsyslog;
    * elk.
4. Настраиваем аудит, который будет отслеживать изменения конфигураций nginx.
    * Все критичные логи с web должны собираться и локально и удаленно.
    * Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
    * Логи аудита должны также уходить на удаленную систему.



Установим nginx на виртуальной машине web:
```
root@ubuntu:~# apt update && apt install -y nginx
```
```
root@ubuntu:~# systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Sat 2026-10-17 13:27:36 UTC; 9min ago
       Docs: man:nginx(8)
    Process: 2971 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 2979 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 3022 (nginx)
      Tasks: 3 (limit: 4600)
     Memory: 2.4M (peak: 5.3M)
        CPU: 28ms
     CGroup: /system.slice/nginx.service
             ├─3022 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             ├─3025 "nginx: worker process"
             └─3026 "nginx: worker process"

Oct 17 13:27:36 ubuntu systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Oct 17 13:27:36 ubuntu systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
root@ubuntu:~# ss -ntlp | grep 80
LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=3026,fd=5),("nginx",pid=3025,fd=5),("nginx",pid=3022,fd=5))
LISTEN 0      4096         0.0.0.0:45803      0.0.0.0:*    users:(("rpc.statd",pid=2370,fd=9))                                            
LISTEN 0      511             [::]:80            [::]:*    users:(("nginx",pid=3026,fd=6),("nginx",pid=3025,fd=6),("nginx",pid=3022,fd=6))
```

Настраиваем центральный сервер сбора логов

rsyslog должен быть установлен по умолчанию.    
Все настройки Rsyslog хранятся в файле /etc/rsyslog.conf    
Для того, чтобы наш сервер мог принимать логи, нам необходимо внести следующие изменения в файл:    
Открываем порт 514 (TCP и UDP):   
Находим закомментированные строки:
```
# provides UDP syslog reception
#module(load="imudp")
#input(type="imudp" port="514")

# provides TCP syslog reception
#module(load="imtcp")
#input(type="imtcp" port="514")
```
И приводим их к виду:
```
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")

# provides TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")
```

В конец файла /etc/rsyslog.conf добавляем правила приёма сообщений от хостов:
```
#ADD remote logg
$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log
*.* ?Remotelogs
& ~
```
Данные параметры будут отправлять в папку /var/log/rsyslog логи, которые будут приходить от других серверов. Например, Access-логи nginx от сервера web, будут идти в файл /var/log/rsyslog/web/nginx_access.log

Далее сохраняем файл и перезапускаем службу rsyslog: systemctl restart rsyslog

```
root@ubuntu:~# ss -nulp
State                Recv-Q               Send-Q                               Local Address:Port                               Peer Address:Port               Process                                                                  
UNCONN               0                    0                                       127.0.0.54:53                                      0.0.0.0:*                   users:(("systemd-resolve",pid=580,fd=16))                               
UNCONN               0                    0                                    127.0.0.53%lo:53                                      0.0.0.0:*                   users:(("systemd-resolve",pid=580,fd=14))                               
UNCONN               0                    0                                          0.0.0.0:111                                     0.0.0.0:*                   users:(("rpcbind",pid=577,fd=5),("systemd",pid=1,fd=160))               
UNCONN               0                    0                                          0.0.0.0:514                                     0.0.0.0:*                   users:(("rsyslogd",pid=3558,fd=5))                                      
UNCONN               0                    0                                             [::]:111                                        [::]:*                   users:(("rpcbind",pid=577,fd=7),("systemd",pid=1,fd=162))               
UNCONN               0                    0                                             [::]:514                                        [::]:*                   users:(("rsyslogd",pid=3558,fd=6))                        
```

Далее настроим отправку логов с web-сервера   

Находим в файле /etc/nginx/nginx.conf раздел с логами и приводим их к следующему виду:   
```
error_log /var/log/nginx/error.log;
error_log syslog:server=172.20.1.20:514,tag=nginx_error;
access_log syslog:server=172.20.1.20:514,tag=nginx_access,severity=info combined;
```
Проверяем конфиг:
```

root@ubuntu:~# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
root@ubuntu:~#  systemctl restart nginx
```

Делаем несколько запросов к nginx:
```
root@ubuntu:~# curl localhost
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Далее заходим на log-сервер и смотрим информацию об nginx:   
* cat /var/log/rsyslog/ubuntu/nginx_access.log 
* cat /var/log/rsyslog/ubuntu/nginx_error.log

```
root@ubuntu:~# cat /var/log/rsyslog/ubuntu/nginx_access.log 
2026-10-17T14:07:31+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:31 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
2026-10-17T14:07:32+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:32 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
2026-10-17T14:07:32+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:32 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
2026-10-17T14:07:33+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:33 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
2026-10-17T14:07:33+00:00 ubuntu nginx_access: message repeated 4 times: [ ::1 - - [17/Oct/2026:14:07:33 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"]
2026-10-17T14:07:34+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:34 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
2026-10-17T14:07:39+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:39 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"
2026-10-17T14:07:40+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:40 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"
2026-10-17T14:07:40+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:40 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"
2026-10-17T14:07:41+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:41 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"
2026-10-17T14:07:41+00:00 ubuntu nginx_access: message repeated 3 times: [ ::1 - - [17/Oct/2026:14:07:41 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"]
2026-10-17T14:07:42+00:00 ubuntu nginx_access: ::1 - - [17/Oct/2026:14:07:42 +0000] "GET /DFG HTTP/1.1" 404 162 "-" "curl/8.5.0"
```

Поскольку наше приложение работает без ошибок, файл nginx_error.log не будет создан. Чтобы сгенерировать ошибку, можно переместить файл веб-страницы, который открывает nginx - 
```
mv /var/www/html/index.nginx-debian.html /var/www/    
```
После этого мы получим 403 ошибку.   
Видим, что логи отправляются корректно.    
```
root@ubuntu:~# cat /var/log/rsyslog/ubuntu/nginx_error.log 
2026-10-17T14:31:06+00:00 ubuntu nginx_error: 2026/10/17 14:31:06 [error] 3307#3307: *2 directory index of "/var/www/html/" is forbidden, client: ::1, server: _, request: "GET / HTTP/1.1", host: "localhost"
2026-10-17T14:31:08+00:00 ubuntu nginx_error: 2026/10/17 14:31:08 [error] 3308#3308: *3 directory index of "/var/www/html/" is forbidden, client: ::1, server: _, request: "GET / HTTP/1.1", host: "localhost"
2026-10-17T14:31:08+00:00 ubuntu nginx_error: 2026/10/17 14:31:08 [error] 3307#3307: *4 directory index of "/var/www/html/" is forbidden, client: ::1, server: _, request: "GET / HTTP/1.1", host: "localhost"
```

