# Домашнее задание
## Практические навыки работы с ZFS


🎯Задание
1. Определить алгоритм с наилучшим сжатием:  
* определить, какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);  
* создать 4 файловых системы, на каждой применить свой алгоритм сжатия;  
* для сжатия использовать либо текстовый файл, либо группу файлов.  
2. Определить настройки пула.  
С помощью команды zfs import собрать pool ZFS.  
Командами zfs определить настройки:  
* размер хранилища;  
* тип pool;  
* значение recordsize;  
* какое сжатие используется;  
* какая контрольная сумма используется.  
3. Работа со снапшотами:  
* скопировать файл из удаленной директории;  
* восстановить файл локально. zfs receive;  
* найти зашифрованное сообщение в файле secret_message.  


### 1. Определение алгоритма с наилучшим сжатием   

Смотрим список всех дисков, которые есть в виртуальной машине: **lsblk**
```
root@ubuntu:~# lsblk
NAME               MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
fd0                  2:0    1    4K  0 disk 
sr0                 11:0    1 1024M  0 rom  
vda                253:0    0   40G  0 disk 
в”њв”Ђvda1             253:1    0    1M  0 part 
в”њв”Ђvda2             253:2    0    2G  0 part /boot
в””в”Ђvda3             253:3    0   38G  0 part 
  в””в”Ђubuntu--vg-lv0 252:0    0   38G  0 lvm  /
vdb                253:16   0   10G  0 disk 
vdc                253:32   0   10G  0 disk 
vdd                253:48   0   10G  0 disk 
vde                253:64   0   10G  0 disk 
vdf                253:80   0    1G  0 disk 
vdg                253:96   0    1G  0 disk 
vdh                253:112  0    1G  0 disk 
vdi                253:128  0    1G  0 disk 
```


Установим пакет утилит для ZFS:
```
root@ubuntu:~# apt install zfsutils-linux
```

Создаём пулы из двух дисков в режиме RAID 1:
```
root@ubuntu:~# zpool create otus1 mirror /dev/vdb /dev/vdc
root@ubuntu:~# zpool create otus2 mirror /dev/vdd /dev/vde
root@ubuntu:~# zpool create otus3 mirror /dev/vdf /dev/vdg
root@ubuntu:~# zpool create otus4 mirror /dev/vdh /dev/vdi
```

Смотрим информацию о пулах: **zpool list**

```
root@ubuntu:~# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1  9.50G   102K  9.50G        -         -     0%     0%  1.00x    ONLINE  -
otus2  9.50G   112K  9.50G        -         -     0%     0%  1.00x    ONLINE  -
otus3   960M   110K   960M        -         -     0%     0%  1.00x    ONLINE  -
otus4   960M   110K   960M        -         -     0%     0%  1.00x    ONLINE  -
```

Команда **zpool status** показывает информацию о каждом диске, состоянии сканирования и об ошибках чтения, записи и совпадения хэш-сумм.   
Команда **zpool list** показывает информацию о размере пула, количеству занятого и свободного места, дедупликации и т.д.   
Добавим разные алгоритмы сжатия в каждую файловую систему:  
* Алгоритм lzjb: zfs set compression=lzjb otus1
* Алгоритм lz4:  zfs set compression=lz4 otus2
* Алгоритм gzip: zfs set compression=gzip-9 otus3
* Алгоритм zle:  zfs set compression=zle otus4

```
root@ubuntu:~# zfs set compression=lzjb otus1
root@ubuntu:~# zfs set compression=lz4 otus2
root@ubuntu:~# zfs set compression=gzip-9 otus3
root@ubuntu:~# zfs set compression=zle otus4
root@ubuntu:~# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия.    
Скачаем один и тот же текстовый файл во все пулы:    
```
root@ubuntu:~# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
```

Проверим, что файл был скачан во все пулы:
```
root@ubuntu:~# ls -l /otus*
/otus1:
total 22129
-rw-r--r-- 1 root root 41250559 Jul  2 07:31 pg2600.converter.log

/otus2:
total 18022
-rw-r--r-- 1 root root 41250559 Jul  2 07:31 pg2600.converter.log

/otus3:
total 10974
-rw-r--r-- 1 root root 41250559 Jul  2 07:31 pg2600.converter.log

/otus4:
total 40313
-rw-r--r-- 1 root root 41250559 Jul  2 07:31 pg2600.converter.log
```

Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3.   
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:   
```
root@ubuntu:~# zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.8M  9.18G  21.6M  /otus1
otus2  17.8M  9.19G  17.6M  /otus2
otus3  10.9M   821M  10.7M  /otus3
otus4  39.5M   792M  39.4M  /otus4
root@ubuntu:~# zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.66x                  -
otus4  compressratio         1.00x                  -
```

Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.    

### 2. Определение настроек пула   

Скачиваем архив в домашний каталог:  
```
root@ubuntu:~# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
--2026-07-26 16:48:52--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Resolving drive.usercontent.google.com (drive.usercontent.google.com)... 209.85.233.132, 2a00:1450:4010:c03::84
Connecting to drive.usercontent.google.com (drive.usercontent.google.com)|209.85.233.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/octet-stream]
Saving to: вЂarchive.tar.gzвЂ™

archive.tar.gz                                             100%[=====================================================================================================================================>]   6.94M  6.49MB/s    in 1.1s    

2026-07-26 16:49:00 (6.49 MB/s) - вЂarchive.tar.gzвЂ™ saved [7275140/7275140]
```

Разархивируем его:   
```
root@ubuntu:~# tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb``

```

Проверим, возможно ли импортировать данный каталог в пул:   
```
root@ubuntu:~# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                         ONLINE
          mirror-0                   ONLINE
            /root/zpoolexport/filea  ONLINE
            /root/zpoolexport/fileb  ONLINE
```

Данный вывод показывает нам имя пула, тип raid и его состав.    
Сделаем импорт данного пула к нам в ОС:   
```
root@ubuntu:~# zpool import -d zpoolexport/ otus
root@ubuntu:~# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                         STATE     READ WRITE CKSUM
        otus                         ONLINE       0     0     0
          mirror-0                   ONLINE       0     0     0
            /root/zpoolexport/filea  ONLINE       0     0     0
            /root/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

  pool: otus1
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus1       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            vdb     ONLINE       0     0     0
            vdc     ONLINE       0     0     0

errors: No known data errors

  pool: otus2
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus2       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            vdd     ONLINE       0     0     0
            vde     ONLINE       0     0     0

errors: No known data errors

  pool: otus3
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus3       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            vdf     ONLINE       0     0     0
            vdg     ONLINE       0     0     0

errors: No known data errors

  pool: otus4
 state: ONLINE
config:

        NAME        STATE     READ WRITE CKSUM
        otus4       ONLINE       0     0     0
          mirror-0  ONLINE       0     0     0
            vdh     ONLINE       0     0     0
            vdi     ONLINE       0     0     0

errors: No known data errors
```

Команда zpool status выдаст нам информацию о составе импортированного пула.   
Если у нас уже есть пул с именем otus, то можно поменять его имя во время импорта: **zpool import -d zpoolexport/ otus newotus**  

Далее нам нужно определить настройки: **zpool get all otus** 
Запрос сразу всех параметром файловой системы: **zfs get all otus**   
```
root@ubuntu:~# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

C помощью команды grep можно уточнить конкретный параметр, например:    
Размер: **zfs get available otus**
```
root@ubuntu:~# zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
```

Тип: **zfs get readonly otus**
```
root@ubuntu:~# zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
```
По типу FS мы можем понять, что позволяет выполнять чтение и запись   

Значение recordsize: **zfs get recordsize otus**
```
root@ubuntu:~# zfs get recordsize otus
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
```

Тип сжатия (или параметр отключения): **zfs get compression otus**  
```
root@ubuntu:~# zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
```

Тип контрольной суммы: **zfs get checksum otus**   
```
root@ubuntu:~# zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

### 3. Работа со снапшотом, поиск сообщения от преподавателя   

Скачаем файл, указанный в задании:   
```
root@ubuntu:~# wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```

Восстановим файловую систему из снапшота:   
**zfs receive otus/test@today < otus_task2.file**   

Далее, ищем в каталоге /otus/test файл с именем “secret_message”:   
```
root@ubuntu:~# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
```

Смотрим содержимое найденного файла:   
```
root@ubuntu:~# cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```

Тут мы видим ссылку на курс OTUS, задание выполнено.   
