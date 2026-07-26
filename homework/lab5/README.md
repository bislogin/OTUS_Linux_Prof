# Домашнее задание
## Работа с NFS


🎯Задание
* запустить 2 виртуальных машины (сервер NFS и клиента);  
* на сервере NFS должна быть подготовлена и экспортирована директория;   
* в экспортированной директории должна быть поддиректория с именем upload с правами на запись в неё;   
* экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab — любым способом);  
* монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3.  

### Настраиваем сервер NFS    
Заходим на сервер c NFS-сервером.   
Дальнейшие действия выполняются от имени пользователя имеющего повышенные привилегии, разрешающие описанные действия.    
Установим сервер NFS:   
```
root@srv:/etc# apt install nfs-kernel-server
```

Настройки сервера находятся в файле /etc/nfs.conf    
Проверяем наличие слушающих портов 2049/udp, 2049/tcp,111/udp, 111/tcp (не все они будут использоваться далее,  но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения):   
```
root@srv:/etc# ss -tnplu 
```

Создаём и настраиваем директорию, которая будет экспортирована в будущем    
```
root@srv:/etc# mkdir -p /srv/share/upload
root@srv:/etc# chown -R nobody:nogroup /srv/share
root@srv:/etc# chmod 0777 /srv/share/upload
```

Экспортируем ранее созданную директорию:   
```
root@srv:/etc# exportfs -r 
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "172.20.1.20/32:/srv/share".
  Assuming default behaviour ('no_subtree_check').
  NOTE: this default has changed since nfs-utils version 1.0.x
```

Проверяем экспортированную директорию следующей командой   
```
root@srv:/etc# exportfs -s 
/srv/share  172.20.1.20/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

### Настраиваем клиент NFS 
Заходим на сервер с клиентом.  
Дальнейшие действия выполняются от имени пользователя имеющего повышенные привилегии, разрешающие описанные действия.   
Установим пакет с NFS-клиентом  
```
root@ubuntu:~# sudo apt install nfs-common
```

Добавляем в /etc/fstab строку    
```
root@ubuntu:~# echo "172.20.1.10:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
```

и выполняем команды:   
```
root@ubuntu:~# systemctl daemon-reload
root@ubuntu:~# systemctl restart remote-fs.target
```

Отметим, что в данном случае происходит автоматическая генерация systemd units в каталоге **/run/systemd/generator/**, которые производят монтирование при первом обращении к каталогу **/mnt/**.
Заходим в директорию **/mnt/** и проверяем успешность монтирования:   
```
root@ubuntu:~# cd /mnt/
root@ubuntu:/mnt# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=67,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=20089)
172.20.1.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=524288,wsize=524288,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=172.20.1.10,mountvers=3,mountport=42432,mountproto=udp,local_lock=none,addr=172.20.1.10)
```

Обратите внимание на `vers=3`, что соответствует NFSv3, как того требует задание.  
