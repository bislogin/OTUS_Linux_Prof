# Домашнее задание
## Архитектура сетей

### Цель:

Научиться менять базовые сетевые настройки в Linux-based системах   

### Дано

![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab19/network.png)

### Планируемая архитектура

Сеть office1

    192.168.2.0/26 - dev
    192.168.2.64/26 - test servers
    192.168.2.128/26 - managers
    192.168.2.192/26 - office hardware

Сеть office2

    192.168.1.0/25 - dev
    192.168.1.128/26 - test servers
    192.168.1.192/26 - office hardware

Сеть central

    192.168.0.0/28 - directors
    192.168.0.32/28 - office hardware
    192.168.0.64/26 - wifi

🎯Задание 

Теоретическая часть

* Найти свободные подсети
* Посчитать сколько узлов в каждой подсети, включая свободные
* Указать broadcast адрес для каждой подсети
* проверить нет ли ошибок при разбиении


Практическая часть

* Соединить офисы в сеть согласно схеме и настроить роутинг
* Все сервера и роутеры должны ходить в инет черз inetRouter
* Все сервера должны видеть друг друга


### 1. Теоретическая часть

Первым шагом мы рассмотрим все сети, указанные в задании. Посчитаем для них количество узлов, найдём Broadcast-адрес, проверим, нет ли ошибок при разбиении.   


<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Network</th>
      <th>Netmask</th>
      <th>N</th>
      <th>Hostmin</th>
      <th>Hostmax</th>
      <th>Broadcast</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th colspan="7">Central Network</th>
    </tr>
    <tr>
      <td>Directors</td>
      <td>192.168.0.0/28</td>
      <td>255.255.255.240</td>
      <td>14</td>
      <td>192.168.0.1</td>
      <td>192.168.0.14</td>
      <td>192.168.0.15</td>
    </tr>
    <tr>
      <td>Office hardware</td>
      <td>192.168.0.32/28</td>
      <td>255.255.255.240</td>
      <td>14</td>
      <td>192.168.0.33</td>
      <td>192.168.0.46</td>
      <td>192.168.0.47</td>
    </tr>
    <tr>
      <td>Wifi(mgt network)</td>
      <td>192.168.0.64/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.0.65</td>
      <td>192.168.0.126</td>
      <td>192.168.0.127</td>
    </tr>
    <tr>
      <th colspan="7">Office 1 network</th>
    </tr>
    <tr>
      <td>Dev</td>
      <td>192.168.2.0/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.2.1</td>
      <td>192.168.2.62</td>
      <td>192.168.2.63</td>
    </tr>
    <tr>
      <td>Test</td>
      <td>192.168.2.64/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.2.65</td>
      <td>192.168.2.126</td>
      <td>192.168.2.127</td>
    </tr>
    <tr>
      <td>Managers</td>
      <td>192.168.2.128/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.2.129</td>
      <td>192.168.2.190</td>
      <td>192.168.2.191</td>
    </tr>
    <tr>
      <td>Office hardware</td>
      <td>192.168.2.192/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.2.193</td>
      <td>192.168.2.254</td>
      <td>192.168.2.255</td>
    </tr>
    <tr>
      <th colspan="7">Office 2 network</th>
    </tr>
    <tr>
      <td>Dev</td>
      <td>192.168.1.0/25</td>
      <td>255.255.255.128</td>
      <td>126</td>
      <td>192.168.1.1</td>
      <td>192.168.1.126</td>
      <td>192.168.1.127</td>
    </tr>
    <tr>
      <td>Test</td>
      <td>192.168.1.128/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.1.129</td>
      <td>192.168.1.190</td>
      <td>192.168.1.191</td>
    </tr>
    <tr>
      <td>Office</td>
      <td>192.168.1.192/26</td>
      <td>255.255.255.192</td>
      <td>62</td>
      <td>192.168.1.193</td>
      <td>192.168.1.254</td>
      <td>192.168.1.255</td>
    </tr>
    <tr>
      <th colspan="7">InetRouter — CentralRouter network</th>
    </tr>
    <tr>
      <td>Inet — central</td>
      <td>192.168.255.0/30</td>
      <td>255.255.255.252</td>
      <td>2</td>
      <td>192.168.255.1</td>
      <td>192.168.255.2</td>
      <td>192.168.255.3</td>
    </tr>
  </tbody>
</table>


После создания таблицы топологии, мы видим, что ошибок в задании нет, также мы сразу видим следующие свободные сети: 

* 192.168.0.16/28 
* 192.168.0.48/28
* 192.168.0.128/25
* 192.168.255.64/26
* 192.168.255.32/27
* 192.168.255.16/28
* 192.168.255.8/29  
* 192.168.255.4/30 


### 2. Практическая часть


Изучив таблицу топологии сети, мы можем построить полную схему сети:

![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab19/net2.png)

На схеме, мы сразу можем увидеть, что нам потребуется создать дополнительно 2 сети (на схеме обозначены полужирными фиолетовыми линиями):
* Для соединения office1Router c centralRouter 
* Для соединения office2Router c centralRouter 

На основании этой схемы мы получаем готовый список серверов.   



<table>
  <thead>
    <tr>
      <th>Server</th>
      <th>IP and Bitmask</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">inetRouter</td>
      <td>Default-NAT address VirtualBox</td>
    </tr>
    <tr>
      <td>192.168.255.1/30</td>
    </tr>
    <tr>
      <td rowspan="6">centralRouter</td>
      <td>192.168.255.2/30</td>
    </tr>
    <tr>
      <td>192.168.0.1/28</td>
    </tr>
    <tr>
      <td>192.168.0.33/28</td>
    </tr>
    <tr>
      <td>192.168.0.65/26</td>
    </tr>
    <tr>
      <td>192.168.255.9/30</td>
    </tr>
    <tr>
      <td>192.168.255.5/30</td>
    </tr>
    <tr>
      <td>centralServer</td>
      <td>192.168.0.2/28</td>
    </tr>
    <tr>
      <td rowspan="5">office1Router</td>
      <td>192.168.255.10/30</td>
    </tr>
    <tr>
      <td>192.168.2.1/26</td>
    </tr>
    <tr>
      <td>192.168.2.65/26</td>
    </tr>
    <tr>
      <td>192.168.2.129/26</td>
    </tr>
    <tr>
      <td>192.168.2.193/26</td>
    </tr>
    <tr>
      <td>office1Server</td>
      <td>192.168.2.130/26</td>
    </tr>
    <tr>
      <td rowspan="4">office2Router</td>
      <td>192.168.255.6/30</td>
    </tr>
    <tr>
      <td>192.168.1.1/26</td>
    </tr>
    <tr>
      <td>192.168.1.129/26</td>
    </tr>
    <tr>
      <td>192.168.1.193/26</td>
    </tr>
    <tr>
      <td>office2Server</td>
      <td>192.168.1.2/26</td>
    </tr>
  </tbody>
</table>


### Настройка NAT
Для того, чтобы на всех серверах работал интернет, на сервере inetRouter должен быть настроен NAT.

```
root@inetRouter:~# iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
```

Создаём файл /etc/iptables_rules.ipv4:
```
# Generated by iptables-save v1.8.10 (nf_tables) on Mon Nov 16 15:46:08 2026
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [373:26480]
-A POSTROUTING ! -d 192.168.0.0/16 -o ens3 -j MASQUERADE
COMMIT
# Completed on Mon Nov 16 15:46:08 2026
```

Создаём файл, в который добавим скрипт автоматического восстановления правил при перезапуске системы:
```
vi /etc/network/if-pre-up.d/iptables

#!/bin/sh
/sbin/iptables-restore < /etc/iptables_rules.ipv4

```

Добавляем права на выполнение файла /etc/network/if-pre-up.d/iptables
```
root@inetRouter:~# sudo chmod +x /etc/network/if-pre-up.d/iptables
```

### Маршрутизация транзитных пакетов (IP forward)   

Важным этапом настройки сетевой лаборатории, является маршрутизация транзитных пакетов. Если объяснить простыми словами — это возможность сервера Linux пропускать трафик через себя к другому серверу. По умолчанию эта функция отключена в Linux. Включить её можно командой:
```
root@centralRouter:~# sudo sysctl -w net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
```
Необходимо включить данную маршрутизацию на всех роутерах.   


### Настройка статических маршрутов

Настройки добавил в отдельный файлах.





