# Домашнее задание
## Сценарии iptables

🎯Задание   

1 реализовать knocking port
* centralRouter может попасть на ssh inetrRouter через knock скрипт
    пример в материалах.
  
2 добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.  
3 запустить nginx на centralServer.  
4 пробросить 80й порт на inetRouter2 8080.  
5 дефолт в инет оставить через inetRouter.  


### 1 реализовать knocking port

На inetRouter прописываем правила iptables:
```
root@inetRouter:~# iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
root@inetRouter:~# iptables -A INPUT -i ens4 -p tcp --dport 7777 -m recent --name KNOCK_OPEN --set -j DROP
root@inetRouter:~# iptables -A INPUT -i ens4 -p tcp --dport 22 -m recent --name KNOCK_OPEN --rcheck --seconds 15 -j ACCEPT
root@inetRouter:~# iptables -A INPUT -i ens4 -p tcp --dport 22 -j DROP
```

Проверим:
```
root@centralRouter:~# ssh root@192.168.255.1 
^C
root@centralRouter:~# ssh root@192.168.255.1 -p 7777
^C
root@centralRouter:~# ssh root@192.168.255.1 
The authenticity of host '192.168.255.1 (192.168.255.1)' can't be established.
ED25519 key fingerprint is SHA256:QJUanw2t+g+pphpEBVWRNo5+NLTMHXa9jxXMa0WwJoU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.255.1' (ED25519) to the list of known hosts.
root@192.168.255.1's password: 
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-49-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Nov 17 06:21:17 AM UTC 2026

  System load:  0.0                Processes:             123
  Usage of /:   18.6% of 37.10GB   Users logged in:       1
  Memory usage: 12%                IPv4 address for ens3: 10.10.10.2
  Swap usage:   0%

 * Canonical Workshop gives developers fast, composable, reproducible, and
   secure developer environments that are perfect for agentic workflows.

   https://ubuntu.com/workshop

Expanded Security Maintenance for Applications is not enabled.

159 updates can be applied immediately.
3 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


*** System restart required ***
Last login: Sun Nov 15 14:21:12 2026 from 172.20.1.10
root@inetRouter:~# 
```

### Добавили inetrouter2:

![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab21/iptables.png)

Создадим файл knock.sh на centralRouter:
```
#!/bin/bash

# IP-адрес inetRouter во внутренней сети
TARGET_IP="192.168.255.1"
USER="root"

# Стучимся в порты (используем nmap с флагом -Pn, чтобы не тратить время на пинг)
for PORT in 7777; do
    nmap -Pn --host-timeout 100 --max-retries 0 -p $PORT $TARGET_IP > /dev/null 2>&1
    sleep 0.5
done

# Подключаемся по SSH
ssh ${USER}@${TARGET_IP}

```


Проверка через скрипт:
```
root@centralRouter:~# chmod +x knock.sh
root@centralRouter:~# ./knock.sh
root@192.168.255.1's password: 
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-49-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Tue Nov 17 06:43:13 AM UTC 2026

  System load:  0.01               Processes:             119
  Usage of /:   18.6% of 37.10GB   Users logged in:       1
  Memory usage: 11%                IPv4 address for ens3: 10.10.10.2
  Swap usage:   0%

 * Canonical Workshop gives developers fast, composable, reproducible, and
   secure developer environments that are perfect for agentic workflows.

   https://ubuntu.com/workshop

Expanded Security Maintenance for Applications is not enabled.

159 updates can be applied immediately.
3 of these updates are standard security updates.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status

New release '26.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


*** System restart required ***
Last login: Tue Nov 17 06:41:20 2026 from 192.168.255.2
root@inetRouter:~# 
```

### 3 запустить nginx на centralServer. 
```
root@centralServers:~# apt install nginx
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  nginx-common
Suggested packages:
  fcgiwrap nginx-doc ssl-cert
The following NEW packages will be installed:
  nginx nginx-common
0 upgraded, 2 newly installed, 0 to remove and 338 not upgraded.
Need to get 570 kB of archives.
After this operation, 1,602 kB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://lv.archive.ubuntu.com/ubuntu noble-updates/main amd64 nginx-common all 1.24.0-2ubuntu7.19 [45.3 kB]
Get:2 http://lv.archive.ubuntu.com/ubuntu noble-updates/main amd64 nginx amd64 1.24.0-2ubuntu7.19 [525 kB]
Fetched 570 kB in 1s (734 kB/s)
Preconfiguring packages ...
Selecting previously unselected package nginx-common.
(Reading database ... 83593 files and directories currently installed.)
Preparing to unpack .../nginx-common_1.24.0-2ubuntu7.19_all.deb ...
Unpacking nginx-common (1.24.0-2ubuntu7.19) ...
Selecting previously unselected package nginx.
Preparing to unpack .../nginx_1.24.0-2ubuntu7.19_amd64.deb ...
Unpacking nginx (1.24.0-2ubuntu7.19) ...
Setting up nginx-common (1.24.0-2ubuntu7.19) ...
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
Setting up nginx (1.24.0-2ubuntu7.19) ...
 * Upgrading binary nginx                                                                                                                                                                                                         [ OK ] 
Processing triggers for man-db (2.12.0-4build2) ...
Processing triggers for ufw (0.36.2-6) ...
Scanning processes...                                                                                                                                                                                                                    
Scanning linux images...                                                                                                                                                                                                                 

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```

### 4 пробросить 80й порт на inetRouter2 8080

На inetRouter2 прописываем:
```
root@inetRouter2:~# sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
root@inetRouter2:~# iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
root@inetRouter2:~# iptables -t nat -A POSTROUTING -d 192.168.0.2 -p tcp --dport 80 -j MASQUERADE
root@inetRouter2:~# iptables -A FORWARD -d 192.168.0.2 -p tcp --dport 80 -j ACCEPT
root@inetRouter2:~# iptables -A FORWARD -s 192.168.0.2 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Проверим на хостовой машине:
```
root@FE:~# curl -I http://192.168.255.14:8080
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Tue, 17 Nov 2026 07:03:15 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 17 Nov 2026 06:57:40 GMT
Connection: keep-alive
ETag: "6afbfae4-267"
Accept-Ranges: bytes
```
