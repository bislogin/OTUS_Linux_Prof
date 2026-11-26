# Домашнее задание
## VPN

🎯Задание  
1)Настроить VPN между двумя ВМ в tun/tap режимах, замерить скорость в туннелях, сделать вывод об отличающихся показателях
2)Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на ВМ

### 1. TUN/TAP режимы VPN

Необходимо выполнить следующие действия на server и client машинах:
```
root@ubuntu:~# apt update
root@ubuntu:~# apt install openvpn iperf3 selinux-utils -y
root@ubuntu:~# setenforce 0
```

#### Настройка хоста 1:
```
# Cоздаем файл-ключ 
root@ubuntu:~# openvpn --genkey secret /etc/openvpn/static.key
# Cоздаем конфигурационный файл OpenVPN
root@ubuntu:~# nano /etc/openvpn/server.conf
                                                                                                   
dev tap
ifconfig 10.10.10.1 255.255.255.0
topology subnet
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
cipher AES-256-CBC
# Создаем service unit для запуска OpenVPN
root@ubuntu:~# nano /etc/systemd/system/openvpn@.service
                                                                                            
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target

# Запускаем сервис
root@ubuntu:~# systemctl start openvpn@server
root@ubuntu:~# systemctl enable openvpn@server

```

#### Настройка хоста 2: 
```
# Cоздаем конфигурационный файл OpenVPN
root@ubuntu:~# nano /etc/openvpn/server.conf
    
dev tap
remote 10.0.10.1    
ifconfig 10.10.10.2 255.255.255.0
topology subnet
route 10.0.10.1 255.255.255.252   
secret /etc/openvpn/static.key
comp-lzo
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
cipher AES-256-CBC
```

На хост 2 в директорию /etc/openvpn необходимо скопировать файл-ключ static.key, который был создан на хосте 1.   

```
# Создаем service unit для запуска OpenVPN
root@ubuntu:~# nano /etc/systemd/system/openvpn@.service
   
[Unit]
Description=OpenVPN Tunneling Application On %I
After=network.target
[Service]
Type=notify
PrivateTmp=true
ExecStart=/usr/sbin/openvpn --cd /etc/openvpn/ --config %i.conf
[Install]
WantedBy=multi-user.target

# Запускаем сервис
root@ubuntu:~# systemctl start openvpn@server
root@ubuntu:~# systemctl enable openvpn@server
```

Далее необходимо замерить скорость в туннеле:

1) На хосте 1 запускаем iperf3 в режиме сервера: iperf3 -s &
```
root@ubuntu:~# iperf3 -s &
```
2) На хосте 2 запускаем iperf3 в режиме клиента и замеряем  скорость в туннеле: iperf3 -c 10.10.10.1 -t 40 -i 5:
```
root@ubuntu:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 36020 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.01   sec   178 MBytes   298 Mbits/sec   91   1.11 MBytes       
[  5]   5.01-10.00  sec   180 MBytes   303 Mbits/sec    0   1.16 MBytes       
[  5]  10.00-15.00  sec   186 MBytes   311 Mbits/sec   46   1.11 MBytes       
[  5]  15.00-20.01  sec   189 MBytes   317 Mbits/sec    9    941 KBytes       
[  5]  20.01-25.01  sec   193 MBytes   324 Mbits/sec  1004    167 KBytes       
[  5]  25.01-30.00  sec   188 MBytes   315 Mbits/sec  110    316 KBytes       
[  5]  30.00-35.00  sec   215 MBytes   361 Mbits/sec    0    633 KBytes       
[  5]  35.00-40.01  sec   198 MBytes   331 Mbits/sec   44    209 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.01  sec  1.49 GBytes   320 Mbits/sec  1304             sender
[  5]   0.00-40.01  sec  1.49 GBytes   319 Mbits/sec                  receiver

iperf Done.
root@ubuntu:~# 
```

Повторяем пункты 1-2 для режима работы tun.   
Получаем следующие перультаты:
```
root@ubuntu:~# iperf3 -c 10.10.10.1 -t 40 -i 5
Connecting to host 10.10.10.1, port 5201
[  5] local 10.10.10.2 port 58850 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-5.00   sec   164 MBytes   274 Mbits/sec  274    172 KBytes       
[  5]   5.00-10.01  sec   173 MBytes   290 Mbits/sec   46    250 KBytes       
[  5]  10.01-15.01  sec   161 MBytes   271 Mbits/sec   69    201 KBytes       
[  5]  15.01-20.00  sec   162 MBytes   272 Mbits/sec   47    198 KBytes       
[  5]  20.00-25.01  sec   168 MBytes   282 Mbits/sec   72    176 KBytes       
[  5]  25.01-30.01  sec   188 MBytes   316 Mbits/sec   47    243 KBytes       
[  5]  30.01-35.01  sec   220 MBytes   369 Mbits/sec  155    225 KBytes       
[  5]  35.01-40.01  sec   184 MBytes   309 Mbits/sec  105    266 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-40.01  sec  1.39 GBytes   298 Mbits/sec  815             sender
[  5]   0.00-40.01  sec  1.39 GBytes   298 Mbits/sec                  receiver

iperf Done.
root@ubuntu:~# 
```


Сравнительный анализ режимов работы OpenVPN (tap и tun)

1. Результаты тестирования пропускной способности (iperf3, 40 сек.)
```
Параметр	                 Режим tap (L2-мост)	Режим tun (L3-туннель)
Средняя скорость передачи	 320 Мбит/с	          298 Мбит/с
Пиковая скорость	         361 Мбит/с	          369 Мбит/с
Объём переданных данных	         1.49 ГБ	          1.39 ГБ
Повторные передачи (Retr)	 1304 пакета	          815 пакетов
```
2. Анализ полученных данных

• Близкая производительность: Оба режима показали сопоставимую пропускную способность (~300–320 Мбит/с). Незначительное расхождение в ~7% обусловлено колебаниями нагрузки на центральный процессор и сети во время замеров.
• Ограничивающий фактор: Скорость туннеля упирается в производительность одного ядра CPU при обработке криптографии (AES-256-CBC) в пространстве пользователя (User-space), поскольку режим статического ключа (--secret) не поддерживает ядерное ускорение Data Channel Offload (DCO).
• Потери пакетов: Наличие повторных передач (Retr) в обоих тестах связано с фрагментацией пакетов при инкапсуляции (превышением MTU физического канала), при этом в режиме tun количество ретрансмитов на 37% ниже за счёт отсутствия лишних Ethernet-заголовков.

3. Сравнение достоинств и недостатков режимов

• Режим tun (сетевой уровень L3 — маршрутизация IP):
	• Достоинства: минимальные накладные расходы (передаются только IP-пакеты), отсутствие широковещательного (broadcast) трафика, высокая масштабируемость, совместимость с мобильными ОС (Android/iOS) и поддержка ускорения в ядре Linux (DCO).
	• Недостатки: не пропускает протоколы канального уровня (ARP, DHCP) и не-IP трафик; требует настройки маршрутизации между подсетями.
• Режим tap (канальный уровень L2 — эмуляция Ethernet):
	• Достоинства: прозрачное объединение удалённых сегментов в единую L2-сеть (bridging), поддержка любых сетевых протоколов и широковещательных запросов (DHCP, Wake-on-LAN, NetBIOS).
	• Недостатки: повышенные накладные расходы из-за инкапсуляции полных Ethernet-кадров, загрузка канала служебным широковещательным трафиком, сложность масштабирования и отсутствие поддержки на мобильных платформах.

4. Итоговый вывод

Для большинства задач по передаче IP-трафика и построению масштабируемых VPN-сетей оптимальным выбором является режим tun благодаря меньшим накладным расходам, отсутствию широковещательного «шума» и возможности аппаратного/ядерного ускорения. Режим tap целесообразно применять только при строгой необходимости передачи немаршрутизируемого L2-трафика или объединения удалённых офисов в единый широковещательный домен.


### RAS на базе OpenVPN 

