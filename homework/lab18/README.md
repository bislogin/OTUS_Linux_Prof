# Домашнее задание
## Настраиваем бэкапы

🎯Задание   
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

*    директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
*    репозиторий для резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
*    имя бекапа должно содержать информацию о времени снятия бекапа;
*    глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех.
*    Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
*    резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
*    написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
*    настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.


Устанавливаем на client и backup сервере borgbackup
```
root@ubuntu:~# apt install borgbackup
```

На сервере backup создаем пользователя и каталог /var/backup и назначаем на него права пользователя borg			

```
root@ubuntu:~# mkdir /var/backup
root@ubuntu:~# chown borg:borg /var/backup/
```

На сервер backup создаем каталог ~/.ssh/authorized_keys в каталоге /home/borg
```
root@ubuntu:~# su - borg
su: warning: cannot change directory to /home/borg: No such file or directory
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

borg@ubuntu:/root$ 
borg@ubuntu:/root$ sudo mkdir .ssh
borg@ubuntu:/root$ sudo touch .ssh/authorized_keys
borg@ubuntu:/root$ sudo chmod 700 .ssh
borg@ubuntu:/root$ sudo chmod 600 .ssh/authorized_keys
borg@ubuntu:/root$ 
```

На сервере client: 
```
ssh-keygen
```
Все дальнейшие действия будут проходить на client сервере.
Инициализируем репозиторий borg на backup сервере с client сервера:
```
root@ubuntu:~# borg init --encryption=repokey borg@172.20.1.20:/var/backup/
(borg@172.20.1.20) Password: 
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: y
Your passphrase (between double-quotes): "password"
Make sure the passphrase displayed above is exactly what you wanted.

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@172.20.1.20/var/backup

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
If you used a repokey mode, the key is stored in the repo, but you should back it up separately.
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```

Запускаем для проверки создания бэкапа
```
root@ubuntu:~# borg create --stats --list borg@172.20.1.20:/var/backup/::"etc-{now:%Y-%m-%d_%H:%M:%S}" /etc
(borg@172.20.1.20) Password: 
Enter passphrase for key ssh://borg@172.20.1.20/var/backup: 
s /etc/localtime
s /etc/mtab
...
d /etc/nginx
d /etc
------------------------------------------------------------------------------
Repository: ssh://borg@172.20.1.20/var/backup
Archive name: etc-2026-10-17_15:49:44
Archive fingerprint: aaa4daf79af26de863bb65c9091cb8407520f6785af4dc539f9134e90b3c3a70
Time (start): Sat, 2026-10-17 15:50:03
Time (end):   Sat, 2026-10-17 15:50:04
Duration: 1.65 seconds
Number of files: 893
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:                2.40 MB              1.07 MB              1.03 MB
All archives:                2.40 MB              1.07 MB              1.12 MB

                       Unique chunks         Total chunks
Chunk index:                     852                  885
------------------------------------------------------------------------------
```

Смотрим, что у нас получилось:
```
root@ubuntu:~# borg list borg@172.20.1.20:/var/backup/
(borg@172.20.1.20) Password: 
Enter passphrase for key ssh://borg@172.20.1.20/var/backup: 
etc-2026-10-17_15:49:44              Sat, 2026-10-17 15:50:03 [aaa4daf79af26de863bb65c9091cb8407520f6785af4dc539f9134e90b3c3a70]
root@ubuntu:~# 
```

Смотрим список файлов:
```
borg list borg@172.20.1.20:/var/backup/::etc-2026-10-17_15:49:44
```

Достаем файл из бекапа:
```
root@ubuntu:~# borg extract borg@172.20.1.20:/var/backup/::etc-2026-10-17_15:49:44 etc/hostname
```

Автоматизируем создание бэкапов с помощью systemd   
Создаем сервис и таймер в каталоге /etc/systemd/system/   
```
vim /etc/systemd/system/borg-backup.service
           
[Unit]
Description=Borg Backup Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment="BORG_PASSPHRASE=password" 
# чтобы в логи попадал список каждого скопированного файла.
ExecStart=/usr/bin/borg create --stats --list borg@172.20.1.20:/var/backup/::"etc-{now:%%Y-%%m-%%d_%%H-%%M-%%S}" /etc

# НАСТРОЙКА ЛОГИРОВАНИЯ В SYSLOG / LOGGER
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=borg-backup

[Install]
WantedBy=multi-user.target
```
```
vim /etc/systemd/system/borg-backup.timer
[Unit]
Description=Run Borg Backup daily

[Timer]
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target

```

Включаем и запускаем службу таймера

```
root@ubuntu:~# systemctl daemon-reload
systemctl enable --now borg-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/borg-backup.timer → /etc/systemd/system/borg-backup.timer.
root@ubuntu:~# systemctl start borg-backup.service
```

Проверяем работу таймера   
```
root@ubuntu:~# systemctl list-timers --all
NEXT                            LEFT LAST                              PASSED UNIT                           ACTIVATES                       
Sat 2026-10-17 16:16:47 UTC 4min 43s Sat 2026-10-17 16:11:47 UTC      16s ago borg-backup.timer              borg-backup.service
Sat 2026-10-17 16:20:00 UTC     7min Sat 2026-10-17 16:10:04 UTC 1min 58s ago sysstat-collect.timer          sysstat-collect.service
Sat 2026-10-17 16:39:22 UTC    27min Sat 2026-10-17 15:59:07 UTC    12min ago fwupd-refresh.timer            fwupd-refresh.service
Sat 2026-10-17 20:08:33 UTC 3h 56min Sat 2026-10-17 16:02:20 UTC     9min ago apt-daily.timer                apt-daily.service
Sun 2026-10-18 00:00:00 UTC       7h Sat 2026-10-17 13:05:59 UTC  3h 6min ago dpkg-db-backup.timer           dpkg-db-backup.service
Sun 2026-10-18 00:00:00 UTC       7h Sat 2026-10-17 13:05:59 UTC  3h 6min ago logrotate.timer                logrotate.service
Sun 2026-10-18 00:07:00 UTC       7h -                                      - sysstat-summary.timer          sysstat-summary.service
Sun 2026-10-18 03:10:48 UTC      10h Sat 2026-10-17 13:05:59 UTC  3h 6min ago e2scrub_all.timer              e2scrub_all.service
Sun 2026-10-18 04:30:03 UTC      12h Sat 2026-10-17 16:11:40 UTC      22s ago man-db.timer                   man-db.service
Sun 2026-10-18 06:39:02 UTC      14h Sat 2026-10-17 13:27:36 UTC 2h 44min ago apt-daily-upgrade.timer        apt-daily-upgrade.service
Sun 2026-10-18 08:15:11 UTC      16h Sat 2026-10-17 13:08:24 UTC  3h 3min ago motd-news.timer                motd-news.service
Sun 2026-10-18 13:10:24 UTC      20h Sat 2026-10-17 13:10:24 UTC  3h 1min ago update-notifier-download.timer update-notifier-download.service
Sun 2026-10-18 13:20:24 UTC      21h Sat 2026-10-17 13:20:24 UTC 2h 51min ago systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Mon 2026-10-19 01:26:32 UTC 1 day 9h Sat 2026-10-17 13:13:04 UTC 2h 58min ago fstrim.timer                   fstrim.service
Wed 2026-10-21 18:02:00 UTC   4 days Sun 2026-10-04 14:29:39 UTC            - update-notifier-motd.timer     update-notifier-motd.service
-                                  - -                                      - apport-autoreport.timer        apport-autoreport.service
-                                  - -                                      - snapd.snap-repair.timer        snapd.snap-repair.service
-                                  - -                                      - ua-timer.timer                 ua-timer.service

18 timers listed.
```
