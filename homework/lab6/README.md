# Домашнее задание
## Размещаем свой RPM в своем репозитории


🎯Задание
1) Создать свой DEB пакет (можно взять свое приложение, либо собрать, например,
Apache с определенными опциями).
2) Создать свой репозиторий и разместить там ранее собранный DEB.



Соберем пакет с кастомным скриптом-приложением в домашней директории  
```
root@ubuntu:/# mkdir -p my-hello-app_1.0.0_amd64/DEBIAN
root@ubuntu:/# mkdir -p my-hello-app_1.0.0_amd64/usr/local/bin
```

Создайте скрипт, который будет устанавливаться в систему, и сделайте его исполняемым:  
```
root@ubuntu:/# cat << 'EOF' > my-hello-app_1.0.0_amd64/usr/local/bin/my-hello
#!/bin/bash
echo "Привет! Это мое кастомное приложение из DEB-пакета!"
EOF
root@ubuntu:/# chmod +x my-hello-app_1.0.0_amd64/usr/local/bin/my-hello
```

Создайте файл метаданных пакета:   
```
root@ubuntu:/# cat << 'EOF' > my-hello-app_1.0.0_amd64/DEBIAN/control
Package: my-hello-app
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Ilya Bazhenov <ilya@example.com>
Description: My first custom greeting application.
 This package provides a simple hello world script.
EOF
```

Упакуйте директорию в готовый .deb файл с помощью dpkg-deb:   
```
root@ubuntu:/# dpkg-deb --build my-hello-app_1.0.0_amd64
dpkg-deb: building package 'my-hello-app' in 'my-hello-app_1.0.0_amd64.deb'.
```

Создание локального APT-репозитория   
Установите пакет dpkg-dev, содержащий утилиту для сканирования репозиториев:   
```
root@ubuntu:/# apt update && apt install -y dpkg-dev
```

Создайте директорию для репозитория и перенесите туда ранее собранный DEB-пакет:   
```
root@ubuntu:/# mkdir -p ~/my-repository/binary
root@ubuntu:/# cp my-hello-app_1.0.0_amd64.deb ~/my-repository/binary/
```

Создадим оба файла индексов — несжатый Packages и сжатый Packages.gz (чтобы APT не выдавал ошибку File not found):   
```
root@ubuntu:/# cd ~/my-repository
root@ubuntu:~/my-repository# dpkg-scanpackages binary /dev/null > binary/Packages
dpkg-scanpackages: warning: Packages in archive but missing from override file:
dpkg-scanpackages: warning:   my-hello-app
dpkg-scanpackages: info: Wrote 1 entries to output Packages file.
root@ubuntu:~/my-repository#  dpkg-scanpackages binary /dev/null | gzip -9c > binary/Packages.gz
dpkg-scanpackages: warning: Packages in archive but missing from override file:
dpkg-scanpackages: warning:   my-hello-app
dpkg-scanpackages: info: Wrote 1 entries to output Packages file.
```

Добавление репозитория в систему   
```
root@ubuntu:~/my-repository# echo "deb [trusted=yes] file:///root/my-repository binary/" | sudo tee /etc/apt/sources.list.d/my-repo.list
deb [trusted=yes] file:///root/my-repository binary/
```

Обновим списки пакетов APT, найдём наше приложение и установим его:   
```
root@ubuntu:~/my-repository# apt update
root@ubuntu:~/my-repository# apt search my-hello-app
Sorting... Done
Full Text Search... Done
my-hello-app/unknown 1.0.0 amd64
  My first custom greeting application.

root@ubuntu:~/my-repository# apt install -y my-hello-app
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  my-hello-app
0 upgraded, 1 newly installed, 0 to remove and 312 not upgraded.
Need to get 0 B/686 B of archives.
After this operation, 0 B of additional disk space will be used.
Get:1 file:/root/my-repository binary/ my-hello-app 1.0.0 [686 B]
Selecting previously unselected package my-hello-app.
(Reading database ... 85897 files and directories currently installed.)
Preparing to unpack .../my-hello-app_1.0.0_amd64.deb ...
Unpacking my-hello-app (1.0.0) ...
Setting up my-hello-app (1.0.0) ...
Scanning processes...                                                                                                                                                                                                                    
Scanning candidates...                                                                                                                                                                                                                   
Scanning linux images...                                                                                                                                                                                                                 

Running kernel seems to be up-to-date.

Restarting services...

Service restarts being deferred:
 systemctl restart unattended-upgrades.service

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```

Запустите установленное приложение из любой точки терминала:   
```
root@ubuntu:~/my-repository# my-hello
Привет! Это мое кастомное приложение из DEB-пакета!
```
