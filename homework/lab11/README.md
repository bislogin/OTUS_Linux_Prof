# Домашнее задание
## Практика c SELinux

### Диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.   


🎯Задание   
1. Запустить nginx на нестандартном порту 3-мя разными способами:
    * переключатели setsebool;
    * добавление нестандартного порта в имеющийся тип;
    * формирование и установка модуля SELinux.


Проводилось на AlmaLinux10.   
После загрузки были прописаны следующие команды:
```
      yum install -y epel-release
      yum install -y nginx
      yum install -y setroubleshoot-server selinux-policy-mls setools-console policycoreutils-python-utils policycoreutils-newrole
      sed -ie 's/:80/:4881/g' /etc/nginx/nginx.conf
      sed -i 's/listen       80;/listen       4881;/' /etc/nginx/nginx.conf
      systemctl start nginx
      systemctl status nginx
```

Во время развёртывания стенда попытка запустить nginx завершится с ошибкой:   
```
[root@localhost ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@localhost ~]# systemctl status nginx
Г— nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; 5:185mdisabled; preset: 5:185mdisabled)
     Active: failed (Result: exit-code) since Tue 2026-08-25 15:10:27 MSK; 7s ago
 Invocation: fa3c7f19e84b465c8aed92fec6498774
    Process: 6100 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6102 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
   Mem peak: 2.9M
        CPU: 42ms

Aug 25 15:10:27 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Aug 25 15:10:27 localhost.localdomain nginx[6102]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Aug 25 15:10:27 localhost.localdomain nginx[6102]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Aug 25 15:10:27 localhost.localdomain nginx[6102]: nginx: configuration file /etc/nginx/nginx.conf test failed
Aug 25 15:10:27 localhost.localdomain systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Aug 25 15:10:27 localhost.localdomain systemd[1]: 5:185m5:185mnginx.service: Failed with result 'exit-code'.
Aug 25 15:10:27 localhost.localdomain systemd[1]: Failed to start nginx.service - The nginx HTTP and reverse proxy server.
```

Данная ошибка появляется из-за того, что SELinux блокирует работу nginx на нестандартном порту.    


#### 1. Запуск nginx на нестандартном порту 3-мя разными способами 

Для начала проверим, что в ОС отключен файервол: systemctl status firewalld
```
[root@localhost ~]# systemctl status firewalld
в—‹ firewalld.service - firewalld - dynamic firewall daemon
     Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; preset: enabled)
     Active: inactive (dead) since Tue 2026-08-25 15:06:44 MSK; 11min ago
 Invocation: e802ccd901f74ee9bbec0cb5fffbbe92
       Docs: man:firewalld(1)
   Main PID: 797 (code=exited, status=0/SUCCESS)
   Mem peak: 49M
        CPU: 1.117s

Aug 25 17:30:37 localhost systemd[1]: Starting firewalld.service - firewalld - dynamic firewall daemon...
Aug 25 17:30:38 localhost systemd[1]: Started firewalld.service - firewalld - dynamic firewall daemon.
Aug 25 15:06:44 localhost.localdomain systemd[1]: Stopping firewalld.service - firewalld - dynamic firewall daemon...
Aug 25 15:06:44 localhost.localdomain systemd[1]: firewalld.service: Deactivated successfully.
Aug 25 15:06:44 localhost.localdomain systemd[1]: Stopped firewalld.service - firewalld - dynamic firewall daemon.
Aug 25 15:06:44 localhost.localdomain systemd[1]: firewalld.service: Consumed 1.117s CPU time, 49M memory peak.
[root@localhost ~]#
```

Также можно проверить, что конфигурация nginx настроена без ошибок: nginx -t
```
[root@localhost ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Далее проверим режим работы SELinux: getenforce 
```
[root@localhost ~]# getenforce
Enforcing
[root@localhost ~]# 
```

Должен отображаться режим Enforcing. Данный режим означает, что SELinux будет блокировать запрещенную активность.   

##### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью переключателей setsebool

Находим в логах (/var/log/audit/audit.log) информацию о блокировании порта   
Копируем время, в которое был записан этот лог, и, с помощью утилиты audit2why смотрим    
```
...
type=AVC msg=audit(1787659827.563:349): avc:  denied  { name_bind } for  pid=6102 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1787659827.563:349): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55941ff8c0e0 a2=10 a3=7fffa66b0430 items=0 ppid=1 pid=6102 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)^]ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
...
```

```
[root@localhost ~]# grep 1787659827.563:349  /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1787659827.563:349): avc:  denied  { name_bind } for  pid=6102 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly. 
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
[root@localhost ~]#
```

Утилита audit2why покажет почему трафик блокируется. Исходя из вывода утилиты, мы видим, что нам нужно поменять параметр nis_enabled.    
Включим параметр nis_enabled и перезапустим nginx: setsebool -P nis_enabled on  
```
[root@localhost ~]# setsebool -P nis_enabled on
[root@localhost ~]# systemctl restart nginx
[root@localhost ~]# systemctl status nginx
в—Џ nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; 5:185mdisabled; preset: 5:185mdisabled)
     Active: active (running) since Tue 2026-08-25 15:24:11 MSK; 6s ago
 Invocation: f737d07f611743e9b88a001dc67b8a36
    Process: 6138 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6140 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6143 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6144 (nginx)
      Tasks: 3 (limit: 23087)
     Memory: 3.1M (peak: 3.2M)
        CPU: 110ms
     CGroup: /system.slice/nginx.service
             в”њв”Ђ6144 "nginx: master process /usr/sbin/nginx"
             в”њв”Ђ6145 "nginx: worker process"
             в””в”Ђ6146 "nginx: worker process"

Aug 25 15:24:11 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Aug 25 15:24:11 localhost.localdomain nginx[6140]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Aug 25 15:24:11 localhost.localdomain nginx[6140]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Aug 25 15:24:11 localhost.localdomain systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
[root@localhost ~]# 
```

Также можно проверить работу nginx из браузера. Заходим в любой браузер на хосте и переходим по адресу http://122.20.1.200:4881

![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab11/alma.png)

Проверить статус параметра можно с помощью команды: getsebool -a | grep nis_enabled
```
[root@localhost ~]# getsebool -a | grep nis_enabled
nis_enabled --> on
[root@localhost ~]# 
```

Вернём запрет работы nginx на порту 4881 обратно. Для этого отключим nis_enabled: setsebool -P nis_enabled off
После отключения nis_enabled служба nginx снова не запустится.

##### Теперь разрешим в SELinux работу nginx на порту TCP 4881 c помощью добавления нестандартного порта в имеющийся тип:

Поиск имеющегося типа, для http трафика: semanage port -l | grep http
```
[root@localhost ~]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
http_port_t                    udp      80, 443
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@localhost ~]#
```

Добавим порт в тип http_port_t: semanage port -a -t http_port_t -p tcp 4881
```
[root@localhost ~]# semanage port -a -t http_port_t -p tcp 4881
[root@localhost ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
http_port_t                    udp      80, 443
pegasus_http_port_t            tcp      5988
[root@localhost ~]# 
```

Теперь перезапускаем службу nginx и проверим её работу: systemctl restart nginx
```
[root@localhost ~]# systemctl restart nginx
[root@localhost ~]# systemctl status nginx
в—Џ nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; 5:185mdisabled; preset: 5:185mdisabled)
     Active: active (running) since Tue 2026-08-25 15:30:53 MSK; 10s ago
 Invocation: 3ca89210d293441e9e310180b84e0351
    Process: 6195 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6197 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6198 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6200 (nginx)
      Tasks: 3 (limit: 23087)
     Memory: 3.1M (peak: 3.3M)
        CPU: 120ms
     CGroup: /system.slice/nginx.service
             в”њв”Ђ6200 "nginx: master process /usr/sbin/nginx"
             в”њв”Ђ6202 "nginx: worker process"
             в””в”Ђ6203 "nginx: worker process"

Aug 25 15:30:52 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Aug 25 15:30:53 localhost.localdomain nginx[6197]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Aug 25 15:30:53 localhost.localdomain nginx[6197]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Aug 25 15:30:53 localhost.localdomain systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
[root@localhost ~]# 
```

Удалить нестандартный порт из имеющегося типа можно с помощью команды: semanage port -d -t http_port_t -p tcp 4881
```
[root@localhost ~]# semanage port -d -t http_port_t -p tcp 4881
[root@localhost ~]# semanage port -l | grep  http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
http_port_t                    udp      80, 443
pegasus_http_port_t            tcp      5988
[root@localhost ~]# 
[root@localhost ~]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@localhost ~]# systemctl status nginx
Г— nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; 5:185mdisabled; preset: 5:185mdisabled)
     Active: failed (Result: exit-code) since Tue 2026-08-25 15:31:46 MSK; 2s ago
   Duration: 53.104s
 Invocation: e09ffd82810e4e85880d70eeaae7e71a
    Process: 6215 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6217 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
   Mem peak: 2.9M
        CPU: 38ms

Aug 25 15:31:46 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Aug 25 15:31:46 localhost.localdomain nginx[6217]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Aug 25 15:31:46 localhost.localdomain nginx[6217]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
Aug 25 15:31:46 localhost.localdomain nginx[6217]: nginx: configuration file /etc/nginx/nginx.conf test failed
Aug 25 15:31:46 localhost.localdomain systemd[1]: nginx.service: Control process exited, code=exited, status=1/FAILURE
Aug 25 15:31:46 localhost.localdomain systemd[1]: 5:185m5:185mnginx.service: Failed with result 'exit-code'.
Aug 25 15:31:46 localhost.localdomain systemd[1]: Failed to start nginx.service - The nginx HTTP and reverse proxy server.
```

##### Разрешим в SELinux работу nginx на порту TCP 4881 c помощью формирования и установки модуля SELinux:

Попробуем снова запустить Nginx: systemctl start nginx
```
[root@localhost ~]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
[root@localhost ~]# 
```

Nginx не запустится, так как SELinux продолжает его блокировать. Посмотрим логи SELinux, которые относятся к Nginx: 
```
...
type=SYSCALL msg=audit(1787661106.293:369): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=558fa943a0c0 a2=10 a3=7ffcc36d7130 items=0 ppid=1 pid=6217 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1787661106.298:370): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
type=AVC msg=audit(1787661223.190:371): avc:  denied  { name_bind } for  pid=6231 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
type=SYSCALL msg=audit(1787661223.190:371): arch=c000003e syscall=49 success=no exit=-13 a0=6 a1=55a1cc6850e0 a2=10 a3=7ffefe3f1100 items=0 ppid=1 pid=6231 auid=4294967295 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295 comm="nginx" exe="/usr/sbin/nginx" subj=system_u:system_r:httpd_t:s0 key=(null)ARCH=x86_64 SYSCALL=bind AUID="unset" UID="root" GID="root" EUID="root" SUID="root" FSUID="root" EGID="root" SGID="root" FSGID="root"
type=SERVICE_START msg=audit(1787661223.196:372): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=nginx comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=failed'UID="root" AUID="unset"
[root@localhost ~]# 
```

Воспользуемся утилитой audit2allow для того, чтобы на основе логов SELinux сделать модуль, разрешающий работу nginx на нестандартном порту: 
```
[root@localhost ~]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

[root@localhost ~]# 
```

Audit2allow сформировал модуль, и сообщил нам команду, с помощью которой можно применить данный модуль: semodule -i nginx.pp
```
[root@localhost ~]# semodule -i nginx.pp
[root@localhost ~]# systemctl start nginx
[root@localhost ~]# systemctl status nginx
в—Џ nginx.service - The nginx HTTP and reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; 5:185mdisabled; preset: 5:185mdisabled)
     Active: active (running) since Tue 2026-08-25 15:36:27 MSK; 6s ago
 Invocation: ef99570d12884326b9364371a6338cc1
    Process: 6254 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    Process: 6256 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
    Process: 6258 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
   Main PID: 6259 (nginx)
      Tasks: 3 (limit: 23087)
     Memory: 3.1M (peak: 3.1M)
        CPU: 65ms
     CGroup: /system.slice/nginx.service
             в”њв”Ђ6259 "nginx: master process /usr/sbin/nginx"
             в”њв”Ђ6261 "nginx: worker process"
             в””в”Ђ6262 "nginx: worker process"

Aug 25 15:36:27 localhost.localdomain systemd[1]: Starting nginx.service - The nginx HTTP and reverse proxy server...
Aug 25 15:36:27 localhost.localdomain nginx[6256]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Aug 25 15:36:27 localhost.localdomain nginx[6256]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Aug 25 15:36:27 localhost.localdomain systemd[1]: Started nginx.service - The nginx HTTP and reverse proxy server.
[root@localhost ~]# 
```

После добавления модуля nginx запустился без ошибок. При использовании модуля изменения сохранятся после перезагрузки.    
Для удаления модуля воспользуемся командой: semodule -r nginx
```
[root@localhost ~]#  semodule -r nginx
libsemanage.semanage_direct_remove_key: Removing last nginx module (no other nginx module exists at another priority).
[root@localhost ~]# 
```









