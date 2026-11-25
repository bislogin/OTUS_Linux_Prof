# Домашнее задание
## OSPF

🎯Задание   
1. Поднять три виртуалки
2. Объединить их разными vlan
* поднять OSPF между машинами на базе Quagga;
* изобразить ассиметричный роутинг;
* сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.


### Настройка OSPF между машинами на базе Quagga

Пакет Quagga перестал развиваться в 2018 году. Ему на смену пришёл пакет FRR, он построен на базе Quagga и продолжает своё развитие. В данном руководстве настойка OSPF будет осуществляться в FRR.  

Процесс установки FRR и настройки OSPF вручную:
1) Отключаем файерволл ufw и удаляем его из автозагрузки:
```
root@ubuntu:~# systemctl stop ufw
root@ubuntu:~# systemctl disable ufw
Synchronizing state of ufw.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable ufw
Removed "/etc/systemd/system/multi-user.target.wants/ufw.service".
```

2) Добавляем gpg ключ:
```
root@ubuntu:~# curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
Warning: apt-key is deprecated. Manage keyring files in trusted.gpg.d instead (see apt-key(8)).
OK
root@ubuntu:~# 
```

3) Добавляем репозиторий c пакетом FRR:
```
root@ubuntu:~# echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable > /etc/apt/sources.list.d/frr.list
```

4) Обновляем пакеты и устанавливаем FRR:
```
root@ubuntu:~# sudo apt update
root@ubuntu:~# sudo apt install frr frr-pythontools
```

5) Разрешаем (включаем) маршрутизацию транзитных пакетов:
```
root@ubuntu:~# sysctl net.ipv4.conf.all.forwarding=1
net.ipv4.conf.all.forwarding = 1
```

6) Включаем демон ospfd в FRR
Для этого открываем в редакторе файл **/etc/frr/daemons** и меняем в нём параметры для пакетов **zebra** и **ospfd** на **yes**:
```
root@ubuntu:~# nano /etc/frr/daemons
...
ospfd=yes
zebra=yes
...
```

7) Настройка OSPF
Для настройки OSPF нам потребуется создать файл /etc/frr/frr.conf который будет содержать в себе информацию о требуемых интерфейсах и OSPF. Разберем пример создания файла на хосте router1. 

Для начала нам необходимо узнать имена интерфейсов и их адреса. 
```
root@ubuntu:~# ip a | grep inet
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host noprefixroute 
    inet 172.20.1.40/24 brd 172.20.1.255 scope global ens3
    inet6 fe80::250:ff:fe00:3100/64 scope link 
    inet 10.0.10.1/30 brd 10.0.10.3 scope global ens4
    inet6 fe80::250:ff:fe00:3101/64 scope link 
    inet 10.0.12.1/30 brd 10.0.12.3 scope global ens5
    inet6 fe80::250:ff:fe00:3102/64 scope link 
    inet 192.168.10.1/24 brd 192.168.10.255 scope global dummy0
    inet6 fe80::90e6:21ff:fe36:e334/64 scope link 
root@ubuntu:~# 
```

Создаём файл /etc/frr/frr.conf и вносим в него следующую информацию:
```

frr version 8.1
frr defaults traditional
hostname router1
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config

interface ens4
 description r1-r2
 ip address 10.0.10.1/30                  
 ip ospf mtu-ignore
 !ip ospf cost 1000
 ip ospf hello-interval 10
 ip ospf dead-interval 30

interface ens5
 description r1-r3
 ip address 10.0.12.1/30
 ip ospf mtu-ignore
 !ip ospf cost 45  
 ip ospf hello-interval 10
 ip ospf dead-interval 30

interface dummy0
 description net_router1
 ip address 192.168.10.1/24
 ip ospf mtu-ignore
 !ip ospf cost 45  
 ip ospf hello-interval 10
 ip ospf dead-interval 30

router ospf
 router-id 1.1.1.1
 network 10.0.10.0/30 area 0 
 network 10.0.12.0/30 area 0
 network 192.168.10.0/24 area 0
 
 
log file /var/log/frr/frr.log
default-information originate always

```

На хостах router2 и router3 также потребуется настроить конфигруационные файлы, предварительно поменяв ip -адреса интерфейсов. 

8) После создания файлов **/etc/frr/frr.conf** и **/etc/frr/daemons** нужно проверить, что владельцем файла является пользователь **frr**. Группа файла также должна быть **frr**. Должны быть установлены следующие права:
* у владельца на чтение и запись
* у группы только на чтение
```
root@ubuntu:~# ls -l /etc/frr
total 28
-rw-r----- 1 frr frr  4138 Nov 25 17:29 daemons
-rw-r----- 1 frr frr  1321 Nov 25 17:39 frr.conf
-rw-r----- 1 frr frr 10383 Aug 26 12:02 support_bundle_commands.conf
-rw-r----- 1 frr frr    32 Aug 26 12:02 vtysh.conf
```

9) Перезапускаем FRR и добавляем его в автозагрузку
```
root@ubuntu:~# systemctl restart frr
root@ubuntu:~# systemctl enable frr
Synchronizing state of frr.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable frr
root@ubuntu:~# 
```

10) Проверям, что OSPF перезапустился без ошибок
```
root@ubuntu:~# systemctl status frr
● frr.service - FRRouting
     Loaded: loaded (/usr/lib/systemd/system/frr.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-11-25 17:49:31 UTC; 2min 23s ago
       Docs: https://frrouting.readthedocs.io/en/latest/setup.html
   Main PID: 3926 (watchfrr)
     Status: "FRR Operational"
      Tasks: 10 (limit: 4614)
     Memory: 20.2M (peak: 34.8M)
        CPU: 469ms
     CGroup: /system.slice/frr.service
             ├─3926 /usr/lib/frr/watchfrr -d mgmtd zebra ospfd staticd
             ├─3937 /usr/lib/frr/mgmtd -d -F traditional -A 127.0.0.1
             ├─3939 /usr/lib/frr/zebra -d -F traditional -A 127.0.0.1 -s 90000000
             ├─3944 /usr/lib/frr/ospfd -d -F traditional -A 127.0.0.1
             └─3947 /usr/lib/frr/staticd -d -F traditional -A 127.0.0.1

Nov 25 17:49:31 ubuntu watchfrr[3926]: [QDG3Y-BY5TN] mgmtd state -> up : connect succeeded
Nov 25 17:49:31 ubuntu watchfrr[3926]: [QDG3Y-BY5TN] staticd state -> up : connect succeeded
Nov 25 17:49:31 ubuntu watchfrr[3926]: [QDG3Y-BY5TN] ospfd state -> up : connect succeeded
Nov 25 17:49:31 ubuntu watchfrr[3926]: [KWE5Q-QNGFC] all daemons up, doing startup-complete notify
Nov 25 17:49:31 ubuntu frrinit.sh[3914]:  * Started watchfrr
Nov 25 17:49:31 ubuntu systemd[1]: Started frr.service - FRRouting.
Nov 25 17:49:42 ubuntu zebra[3939]: [SAPXX-HP5B5][EC 4043309108] Extended Error: failed to retrieve link settings
Nov 25 17:49:42 ubuntu zebra[3939]: [WVJCK-PPMGD][EC 4043309093] generic-netlink-cmd (NS 0) error: Operation not supported, type=RTM_GETADDR(22), seq=110, pid=3938
Nov 25 17:49:42 ubuntu zebra[3939]: [SAPXX-HP5B5][EC 4043309108] Extended Error: failed to retrieve link settings
Nov 25 17:49:42 ubuntu zebra[3939]: [WVJCK-PPMGD][EC 4043309093] generic-netlink-cmd (NS 0) error: Operation not supported, type=RTM_GETADDR(22), seq=115, pid=3938
```

Проверим доступность сетей с хоста router1:
* попробуем сделать ping до ip-адреса 192.168.30.1
```
root@ubuntu:~# ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.496 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=0.957 ms
64 bytes from 192.168.30.1: icmp_seq=3 ttl=64 time=0.845 ms
64 bytes from 192.168.30.1: icmp_seq=4 ttl=64 time=0.859 ms
^C
--- 192.168.30.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3038ms
rtt min/avg/max/mdev = 0.496/0.789/0.957/0.174 ms
```

* Запустим трассировку до адреса 192.168.30.1
```
root@ubuntu:~# traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  192.168.30.1 (192.168.30.1)  0.836 ms  0.755 ms  0.707 ms
root@ubuntu:~# 
```

Попробуем отключить интерфейс ens5 и немного подождем и снова запустим трассировку до ip-адреса 192.168.30.1
```
root@ubuntu:~# ifconfig ens5 down
root@ubuntu:~# ip a | grep ens5
4: ens5: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
root@ubuntu:~# traceroute 192.168.30.1
traceroute to 192.168.30.1 (192.168.30.1), 30 hops max, 60 byte packets
 1  10.0.10.2 (10.0.10.2)  0.653 ms  0.612 ms  0.590 ms
 2  192.168.30.1 (192.168.30.1)  1.096 ms  1.076 ms  1.019 ms
root@ubuntu:~# 
```

Как мы видим, после отключения интерфейса сеть 192.168.30.0/24 нам остаётся доступна.

### Настройка ассиметричного роутинга

Для настройки ассиметричного роутинга нам необходимо выключить блокировку ассиметричной маршрутизации:
```
root@ubuntu:~# sysctl net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.all.rp_filter = 0
```

Далее, выбираем один из роутеров, на котором изменим «стоимость интерфейса». Например поменяем стоимость интерфейса ens5 на router1:
```
root@ubuntu:~# vtysh 

Hello, this is FRRouting (version 10.7.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

ubuntu# conf t
ubuntu(config-if)# interface ens5
% Configuration applied with notes:
No changes found to be committed!
ubuntu(config-if)# ip ospf cost 1000
ubuntu(config-if)# exit
ubuntu(config)# exit
ubuntu# show ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

IPv4 unicast VRF default:
O>* 10.0.11.0/30 [110/11] via 10.0.10.2, ens4, weight 1, 00:18:04
O   10.0.12.0/30 [110/21] via 10.0.10.2, ens4, weight 1, 00:00:12
O>* 192.168.20.0/24 [110/20] via 10.0.10.2, ens4, weight 1, 00:18:04
O>* 192.168.30.0/24 [110/21] via 10.0.10.2, ens4, weight 1, 00:00:12
ubuntu# 
```
На роутере2:
```
root@ubuntu:~# vtysh 

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

ubuntu# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1] is directly connected, ens4, weight 1, 00:19:53
O   10.0.11.0/30 [110/1] is directly connected, ens5, weight 1, 00:19:53
O>* 10.0.12.0/30 [110/11] via 10.0.11.1, ens5, weight 1, 00:01:29
O>* 192.168.10.0/24 [110/11] via 10.0.10.1, ens4, weight 1, 00:19:21
O   192.168.20.0/24 [110/10] is directly connected, dummy0, weight 1, 00:19:53
O>* 192.168.30.0/24 [110/11] via 10.0.11.1, ens5, weight 1, 00:19:16
ubuntu#
```

После внесения данных настроек, мы видим, что маршрут до сети 192.168.30.0/24  теперь пойдёт через router2, но обратный трафик от router2 пойдёт по другому пути. Проверим:
1) На router1 запускаем пинг от 192.168.10.1 до 192.168.30.1:
```
root@ubuntu:~# ping -I 192.168.10.1 192.168.30.1
PING 192.168.30.1 (192.168.30.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.977 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=1.19 ms
64 bytes from 192.168.30.1: icmp_seq=3 ttl=64 time=1.21 ms
64 bytes from 192.168.30.1: icmp_seq=4 ttl=64 time=1.20 ms
64 bytes from 192.168.30.1: icmp_seq=5 ttl=64 time=1.19 ms
...
```

2) На router3 запускаем tcpdump, который будет смотреть трафик только на порту ens5:
```
root@ubuntu:~# tcpdump -i ens5
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens5, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:17:19.192365 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 71, length 64
18:17:20.193996 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 72, length 64
18:17:21.195552 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 73, length 64
18:17:22.197111 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 74, length 64
18:17:22.615983 IP 10.0.12.1 > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:17:23.198640 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 75, length 64
18:17:24.200338 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 76, length 64
18:17:24.974658 IP ubuntu > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:17:25.201882 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 77, length 64
18:17:26.203716 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 78, length 64
18:17:27.205390 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4441, seq 79, length 64
^C
11 packets captured
11 packets received by filter
0 packets dropped by kernel
root@ubuntu:~#
```
Видим что данный порт только отправляет ICMP-трафик на адрес 192.168.10.1   


3) На router2 запускаем tcpdump, который будет смотреть трафик только на порту ens4:
```
root@ubuntu:~# tcpdump -i ens4
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens4, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:17:30.210313 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 82, length 64
18:17:31.212031 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 83, length 64
18:17:32.213561 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 84, length 64
18:17:32.928950 IP 10.0.11.2 > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:17:33.214935 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 85, length 64
18:17:34.216367 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 86, length 64
18:17:34.975100 IP ubuntu > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:17:35.217985 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 87, length 64
18:17:36.219129 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 88, length 64
18:17:37.240347 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4441, seq 89, length 64
^C
10 packets captured
10 packets received by filter
0 packets dropped by kernel
root@ubuntu:~# 
```
Видим что данный порт только получает ICMP-трафик с адреса 192.168.10.1   
Таким образом мы видим ассиметричный роутинг.   

### Настройка симметичного роутинга

Так как у нас уже есть один «дорогой» интерфейс, нам потребуется добавить ещё один дорогой интерфейс, чтобы у нас перестала работать ассиметричная маршрутизация. 

Так как в прошлом задании мы заметили что router3 будет отправлять обратно трафик через порт ens5, мы также должны сделать его дорогим и далее проверить, что теперь используется симметричная маршрутизация:

Поменяем стоимость интерфейса ens5 на router3:
```
root@ubuntu:~# vtysh 

Hello, this is FRRouting (version 10.7.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

ubuntu# conf t
ubuntu(config)# int ens5
% Configuration applied with notes:
No changes found to be committed!
ubuntu(config-if)# ip ospf cost 1000
ubuntu(config-if)# exit
ubuntu(config)# exit
ubuntu# show ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

IPv4 unicast VRF default:
O>* 10.0.10.0/30 [110/11] via 10.0.11.2, ens4, weight 1, 00:32:27
O>* 192.168.10.0/24 [110/21] via 10.0.11.2, ens4, weight 1, 00:00:14
O>* 192.168.20.0/24 [110/20] via 10.0.11.2, ens4, weight 1, 00:32:27
```

1) На router1 запускаем пинг от 192.168.10.1 до 192.168.30.1: 
ping -I 192.168.10.1 192.168.30.1
```
root@ubuntu:~# ping -I 192.168.10.1 192.168.30.1
PING 192.168.30.1 (192.168.30.1) from 192.168.10.1 : 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=1.07 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=1.15 ms
64 bytes from 192.168.30.1: icmp_seq=3 ttl=64 time=1.15 ms
64 bytes from 192.168.30.1: icmp_seq=4 ttl=64 time=1.38 ms
64 bytes from 192.168.30.1: icmp_seq=5 ttl=64 time=1.11 ms
```

2) На router3 запускаем tcpdump, который будет смотреть трафик только на порту ens4:
```
root@ubuntu:~# tcpdump -i ens4
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on ens4, link-type EN10MB (Ethernet), snapshot length 262144 bytes
18:25:33.641157 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4449, seq 51, length 64
18:25:33.641205 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4449, seq 51, length 64
18:25:34.643059 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4449, seq 52, length 64
18:25:34.643106 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4449, seq 52, length 64
18:25:35.028945 IP ubuntu > ospf-all.mcast.net: OSPFv2, Hello, length 48
18:25:35.644896 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4449, seq 53, length 64
18:25:35.644944 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4449, seq 53, length 64
18:25:36.646642 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4449, seq 54, length 64
18:25:36.646691 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4449, seq 54, length 64
18:25:37.648394 IP 192.168.10.1 > ubuntu: ICMP echo request, id 4449, seq 55, length 64
18:25:37.648445 IP ubuntu > 192.168.10.1: ICMP echo reply, id 4449, seq 55, length 64
^C
11 packets captured
11 packets received by filter
0 packets dropped by kernel
root@ubuntu:~# 
```

Теперь мы видим, что трафик между роутерами ходит симметрично.
