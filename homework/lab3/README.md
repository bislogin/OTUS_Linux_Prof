# Домашнее задание
## Файловые системы и LVM-1


🎯Задание
На виртуальной машине с Ubuntu 24.04 и LVM.  

1. Уменьшить том под / до 8G.  
2. Выделить том под /home.  
3. Выделить том под /var - сделать в mirror.  
4. /home - сделать том для снапшотов.  
5. Прописать монтирование в fstab. Попробовать с разными опциями и разными файловыми системами (на выбор).  
6. Работа со снапшотами:  
* сгенерить файлы в /home/;  
* снять снапшот;  
* удалить часть файлов;  
* восстановиться со снапшота.

### LVM - начало работы   

Почти все команды требуют прав суперпользователя, поэтому сразу переходим в root:  
```
sudo -i
```

Для начала необходимо определиться какие устройства мы хотим использовать в  
качестве Physical Volumes (далее - PV) для наших будущих Volume Groups (далее - VG). Для этого можно воспользоваться lsblk:  
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
```

На выделенных дисках будем экспериментировать. Диски vdb, vdc будем использовать для базовых вещей и снапшотов. На дисках vdd,vde создадим lvm mirror.  

Также можно воспользоваться утилитой lvmdiskscan:  
```
root@ubuntu:~# lvmdiskscan
  /dev/vda2 [       2.00 GiB] 
  /dev/vda3 [     <38.00 GiB] LVM physical volume
  /dev/vdb  [      10.00 GiB] 
  /dev/vdc  [      10.00 GiB] 
  /dev/vdd  [      10.00 GiB] 
  /dev/vde  [      10.00 GiB] 
  4 disks
  1 partition
  0 LVM physical volume whole disks
  1 LVM physical volume
```

Для начала разметим диск для будущего использования LVM - создадим PV:  
```
root@ubuntu:~# pvcreate /dev/vdb
  Physical volume "/dev/vdb" successfully created.
```

Затем можно создавать первый уровень абстракции - VG:  
```
root@ubuntu:~# vgcreate otus /dev/vdb
  Volume group "otus" successfully created
```

И в итоге создать Logical Volume (далее - LV):  
```
root@ubuntu:~# lvcreate -l+80%FREE -n test otus
  Logical volume "test" created.
```

Посмотреть информацию о только что созданном Volume Group:  
```
root@ubuntu:~# vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2047 / <8.00 GiB
  Free  PE / Size       512 / 2.00 GiB
  VG UUID               lvVOa8-gCYS-lZ7O-810t-PX3W-Y7iv-ykhRI4
```

В сжатом виде информацию можно получить командами vgs и lvs:   
```
root@ubuntu:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  otus        1   1   0 wz--n- <10.00g 2.00g
  ubuntu-vg   1   1   0 wz--n- <38.00g    0 
root@ubuntu:~# lvs
  LV   VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus      -wi-a-----  <8.00g                                                    
  lv0  ubuntu-vg -wi-ao---- <38.00g
```

Мы можем создать еще один LV из свободного места.   
```
root@ubuntu:~# lvcreate -L 100M -n small otus
  Logical volume "small" created.
```

```
root@ubuntu:~# lvs
  LV    VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  small otus      -wi-a----- 100.00m                                                    
  test  otus      -wi-a-----  <8.00g                                                    
  lv0   ubuntu-vg -wi-ao---- <38.00g
```

Создадим на LV файловую систему и смонтируем его:  
```
root@ubuntu:~# mkfs.ext4 /dev/otus/test
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 2096128 4k blocks and 524288 inodes
Filesystem UUID: c905fc73-2ebb-4f2d-b79d-90ac1da021b8
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@ubuntu:~# mkdir /data
root@ubuntu:~# mount /dev/otus/test /data/
```

```
root@ubuntu:~# df -Th
Filesystem                 Type   Size  Used Avail Use% Mounted on
tmpfs                      tmpfs  392M  1.1M  391M   1% /run
/dev/mapper/ubuntu--vg-lv0 ext4    38G  6.3G   29G  18% /
tmpfs                      tmpfs  2.0G     0  2.0G   0% /dev/shm
tmpfs                      tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/vda2                  ext4   2.0G   95M  1.7G   6% /boot
tmpfs                      tmpfs  392M   12K  392M   1% /run/user/0
tmpfs                      tmpfs  392M   12K  392M   1% /run/user/1001
/dev/mapper/otus-test      ext4   7.8G   24K  7.4G   1% /data
```

### Расширение LVM   

Допустим, перед нами встала проблема нехватки свободного места в директории /data. Мы можем расширить файловую систему на LV /dev/otus/test за счет нового блочного устройства /dev/vdc.  
Для начала так же необходимо создать PV:  
```
root@ubuntu:~# pvcreate /dev/vdc
  Physical volume "/dev/vdc" successfully created.
```

Далее необходимо расширить VG добавив в него этот диск.  
```
root@ubuntu:~# vgextend otus /dev/vdc
  Volume group "otus" successfully extended
```

Убедимся что новый диск присутствует в новой VG:  
```
root@ubuntu:~# vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/vdb     
  PV Name               /dev/vdc     
root@ubuntu:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree  
  otus        2   2   0 wz--n-  19.99g <11.90g
  ubuntu-vg   1   1   0 wz--n- <38.00g      0 
```

Сымитируем занятое место с помощью команды dd для большей наглядности:  
```
root@ubuntu:~# dd if=/dev/zero of=/data/test.log bs=1M \
 count=8000 status=progress
7707033600 bytes (7.7 GB, 7.2 GiB) copied, 9 s, 856 MB/s
dd: error writing '/data/test.log': No space left on device
7944+0 records in
7943+0 records out
8329297920 bytes (8.3 GB, 7.8 GiB) copied, 9.91116 s, 840 MB/s
```

Теперь у нас занято 100% дискового пространства:  
```
root@ubuntu:~# df -Th
Filesystem                 Type   Size  Used Avail Use% Mounted on
tmpfs                      tmpfs  392M  1.1M  391M   1% /run
/dev/mapper/ubuntu--vg-lv0 ext4    38G  6.3G   29G  18% /
tmpfs                      tmpfs  2.0G     0  2.0G   0% /dev/shm
tmpfs                      tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/vda2                  ext4   2.0G   95M  1.7G   6% /boot
tmpfs                      tmpfs  392M   12K  392M   1% /run/user/0
tmpfs                      tmpfs  392M   12K  392M   1% /run/user/1001
/dev/mapper/otus-test      ext4   7.8G  7.8G     0 100% /data
```

Увеличиваем LV за счет появившегося свободного места. Возьмем не все место — это для того, чтобы осталось место для демонстрации снапшотов:  
```
root@ubuntu:~# lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <8.00 GiB (2047 extents) to <17.52 GiB (4484 extents).
  Logical volume otus/test successfully resized.
```

Наблюдаем, что LV расширен до 17.52g:  
```
root@ubuntu:~# lvs /dev/otus/test
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- <17.52g  
```

Но файловая система при этом осталась прежнего размера:   
```
root@ubuntu:~# df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data
```

Произведем resize файловой системы:   
```
root@ubuntu:~# resize2fs /dev/otus/test
resize2fs 1.47.0 (5-Feb-2023)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 3
The filesystem on /dev/otus/test is now 4591616 (4k) blocks long.

root@ubuntu:~# df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4   18G  7.8G  8.6G  48% /data
```

Допустим мы забыли оставить место на снапшоты. Можно уменьшить существующий LV с помощью команды lvreduce, но перед этим необходимо отмонтировать файловую систему, проверить её на ошибки и уменьшить ее размер:  
```
root@ubuntu:~# umount /data/
root@ubuntu:~# e2fsck -fy /dev/otus/test
e2fsck 1.47.0 (5-Feb-2023)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/otus/test: 12/1155072 files (0.0% non-contiguous), 2133660/4591616 blocks
root@ubuntu:~# resize2fs /dev/otus/test 10G
resize2fs 1.47.0 (5-Feb-2023)
Resizing the filesystem on /dev/otus/test to 2621440 (4k) blocks.
The filesystem on /dev/otus/test is now 2621440 (4k) blocks long.

root@ubuntu:~# lvreduce /dev/otus/test -L 10G
  WARNING: Reducing active logical volume to 10.00 GiB.
  THIS MAY DESTROY YOUR DATA (filesystem etc.)
Do you really want to reduce otus/test? [y/n]: y
  Size of logical volume otus/test changed from <17.52 GiB (4484 extents) to 10.00 GiB (2560 extents).
  Logical volume otus/test successfully resized.

root@ubuntu:~# mount /dev/otus/test /data/
```

Убедимся, что ФС и lvm необходимого размера:  
```
root@ubuntu:~# df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  9.8G  7.8G  1.6G  84% /data
root@ubuntu:~# lvs /dev/otus/test
  LV   VG   Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- 10.00g           
```

### Работа со снапшотами   

Снапшот создается командой lvcreate, только с флагом -s, который указывает на то, что это снимок:  
```
root@ubuntu:~# lvcreate -L 500M -s -n test-snap /dev/otus/test
  Logical volume "test-snap" created.
```

Проверим с помощью vgs:  
```
root@ubuntu:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree 
  otus        2   3   1 wz--n-  19.99g <9.41g
  ubuntu-vg   1   1   0 wz--n- <38.00g     0 
```

Команда lsblk, например, нам наглядно покажет, что произошло:  
```
root@ubuntu:~# lsblk
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
fd0                     2:0    1    4K  0 disk 
sr0                    11:0    1 1024M  0 rom  
vda                   253:0    0   40G  0 disk 
в”њв”Ђvda1                253:1    0    1M  0 part 
в”њв”Ђvda2                253:2    0    2G  0 part /boot
в””в”Ђvda3                253:3    0   38G  0 part 
  в””в”Ђubuntu--vg-lv0    252:0    0   38G  0 lvm  /
vdb                   253:16   0   10G  0 disk 
в”њв”Ђotus-small          252:2    0  100M  0 lvm  
в””в”Ђotus-test-real      252:3    0   10G  0 lvm  
  в”њв”Ђotus-test         252:1    0   10G  0 lvm  /data
  в””в”Ђotus-test--snap   252:5    0   10G  0 lvm  
vdc                   253:32   0   10G  0 disk 
в”њв”Ђotus-test-real      252:3    0   10G  0 lvm  
в”‚ в”њв”Ђotus-test         252:1    0   10G  0 lvm  /data
в”‚ в””в”Ђotus-test--snap   252:5    0   10G  0 lvm  
в””в”Ђotus-test--snap-cow 252:4    0  500M  0 lvm  
  в””в”Ђotus-test--snap   252:5    0   10G  0 lvm  
vdd                   253:48   0   10G  0 disk 
vde                   253:64   0   10G  0 disk 
```

Здесь otus-test-real — оригинальный LV, otus-test--snap — снапшот, а otus-test--snap-cow — copy-on-write, сюда пишутся изменения.
Снапшот можно смонтировать как и любой другой LV:  
```
root@ubuntu:~# mkdir /data-snap
root@ubuntu:~# mount /dev/otus/test-snap /data-snap/
root@ubuntu:~# ll /data-snap/
total 8134108
drwxr-xr-x  3 root root       4096 Jul 16 09:39 ./
drwxr-xr-x 25 root root       4096 Jul 16 09:52 ../
drwx------  2 root root      16384 Jul 16 09:27 lost+found/
-rw-r--r--  1 root root 8329297920 Jul 16 09:39 test.log
root@ubuntu:~# umount /data-snap
```

Можно также восстановить предыдущее состояние. “Откатиться” на снапшот. Для этого сначала для большей наглядности удалим наш log файл:  
```
root@ubuntu:~# rm /data/test.log
root@ubuntu:~# ll /data
total 24
drwxr-xr-x  3 root root  4096 Jul 16 09:53 ./
drwxr-xr-x 25 root root  4096 Jul 16 09:52 ../
drwx------  2 root root 16384 Jul 16 09:27 lost+found/
root@ubuntu:~# umount /data
root@ubuntu:~# lvconvert --merge /dev/otus/test-snap
  Merging of volume otus/test-snap started.
  otus/test: Merged: 100.00%
root@ubuntu:~# mount /dev/otus/test /data
root@ubuntu:~# ll /data
total 8134108
drwxr-xr-x  3 root root       4096 Jul 16 09:39 ./
drwxr-xr-x 25 root root       4096 Jul 16 09:52 ../
drwx------  2 root root      16384 Jul 16 09:27 lost+found/
-rw-r--r--  1 root root 8329297920 Jul 16 09:39 test.log
```

### Работа с LVM-RAID   

```
root@ubuntu:~# pvcreate /dev/vd{d,e}
  Physical volume "/dev/vdd" successfully created.
  Physical volume "/dev/vde" successfully created.
root@ubuntu:~# vgcreate vg0 /dev/vd{d,e}
  Volume group "vg0" successfully created
root@ubuntu:~# lvcreate -l+80%FREE -m1 -n mirror vg0
  Logical volume "mirror" created.
root@ubuntu:~# lvs
  LV     VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  small  otus      -wi-a----- 100.00m                                                    
  test   otus      -wi-ao----  10.00g                                                    
  lv0    ubuntu-vg -wi-ao---- <38.00g                                                    
  mirror vg0       rwi-a-r---  <8.00g                                    11.94
```


### Уменьшить том под / до 8G
Воспользуемся чистым сдендом.     
Подготовим временный том для / раздела:

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
root@ubuntu:~#  pvcreate /dev/vdb
  Physical volume "/dev/vdb" successfully created.
root@ubuntu:~# vgcreate vg_root /dev/vdb
  Volume group "vg_root" successfully created
root@ubuntu:~# lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.
```

Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:  
```
root@ubuntu:~# mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 2620416 4k blocks and 655360 inodes
Filesystem UUID: b4ac505d-1d0d-478b-9d29-79c05c550b90
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@ubuntu:~# mount /dev/vg_root/lv_root /mnt
```

Копируем все данные с / раздела в /mnt:  
```
root@ubuntu:~# rsync -avxHAX --progress / /mnt/
...
sent 6,554,257,923 bytes  received 1,526,033 bytes  53,516,603.72 bytes/sec
total size is 6,551,271,543  speedup is 1.00
```

Сконфигурируем grub для того, чтобы при старте перейти в новый /.
Сымитируем текущий root, сделаем в него chroot и обновим grub:  
```
root@ubuntu:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done
root@ubuntu:~# chroot /mnt/
root@ubuntu:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-49-generic
Found initrd image: /boot/initrd.img-6.8.0-49-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
```

Обновим образ initrd. Что это такое и зачем нужно вы узнаете из следующей лекции. Перезагружаемся, чтобы работать с новым разделом. 
```
root@ubuntu:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-49-generic
root@ubuntu:/# reboot
```

Посмотрим картину с дисками после перезагрузки:  
```
root@ubuntu:~# lsblk 
NAME               MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
fd0                  2:0    1    4K  0 disk 
sr0                 11:0    1 1024M  0 rom  
vda                253:0    0   40G  0 disk 
в”њв”Ђvda1             253:1    0    1M  0 part 
в”њв”Ђvda2             253:2    0    2G  0 part /boot
в””в”Ђvda3             253:3    0   38G  0 part 
  в””в”Ђubuntu--vg-lv0 252:1    0   38G  0 lvm  
vdb                253:16   0   10G  0 disk 
в””в”Ђvg_root-lv_root  252:0    0   10G  0 lvm  /
vdc                253:32   0   10G  0 disk 
vdd                253:48   0   10G  0 disk 
vde                253:64   0   10G  0 disk 
```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 40G и создаём новый на 8G:  
```
root@ubuntu:~# lvremove /dev/ubuntu-vg/lv0 
Do you really want to remove and DISCARD active logical volume ubuntu-vg/lv0? [y/n]: y
  Logical volume "lv0" successfully removed.
root@ubuntu:~# lvcreate -n ubuntu-vg/lv0 -L 8G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/lv0 at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/lv0.
  Logical volume "lv0" created.
```

Проделываем на нем те же операции, что и в первый раз:  
```
root@ubuntu:~# mkfs.ext4 /dev/ubuntu-vg/lv0
root@ubuntu:~# mount /dev/ubuntu-vg/lv0 /mnt
rsync -avxHAX --progress / /mnt/
...
sent 6,571,245,468 bytes  received 1,526,197 bytes  46,781,292.99 bytes/sec
total size is 6,568,253,462  speedup is 1.00
```

Так же как в первый раз cконфигурируем grub.  
```
root@ubuntu:~# for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done
root@ubuntu:~# chroot /mnt/
root@ubuntu:/# grub-mkconfig -o /boot/grub/grub.cfg
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-49-generic
Found initrd image: /boot/initrd.img-6.8.0-49-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
root@ubuntu:/# update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.8.0-49-generic
W: Couldn't identify type of root file system for fsck hook
```

#### Пока не перезагружаемся и не выходим из под chroot - мы можем заодно перенести /var.

##### Выделить том под /var в зеркало  
На свободных дисках создаем зеркало:   
```
root@ubuntu:/# pvcreate /dev/vdc /dev/vdd
  Physical volume "/dev/vdc" successfully created.
  Physical volume "/dev/vdd" successfully created.
root@ubuntu:/# vgcreate vg_var /dev/vdc /dev/vdd
  Volume group "vg_var" successfully created
root@ubuntu:/# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```

Создаем на нем ФС и перемещаем туда /var:  
```
root@ubuntu:/# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 243712 4k blocks and 60928 inodes
Filesystem UUID: c1b1741a-ab5c-4aff-bb73-39c445554708
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

root@ubuntu:/# mount /dev/vg_var/lv_var /mnt
root@ubuntu:/# cp -aR /var/* /mnt/
```

На всякий случай сохраняем содержимое старого var (или же можно его просто удалить):  
```
root@ubuntu:/# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```

Монтируем новый var в каталог /var:  
```
root@ubuntu:/# umount /mnt
root@ubuntu:/# mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:  
```
root@ubuntu:/# echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab
```

После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять
временную Volume Group:  
```
root@ubuntu:~# lvs
  LV      VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv0     ubuntu-vg -wi-ao----   8.00g                                                    
  lv_root vg_root   -wi-a----- <10.00g                                                    
  lv_var  vg_var    rwi-aor--- 952.00m                                    100.00          
root@ubuntu:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree  
  ubuntu-vg   1   1   0 wz--n- <38.00g <30.00g
  vg_root     1   1   0 wz--n- <10.00g      0 
  vg_var      2   1   0 wz--n-  19.99g  18.12g
root@ubuntu:~# pvs
  PV         VG        Fmt  Attr PSize   PFree  
  /dev/vda3  ubuntu-vg lvm2 a--  <38.00g <30.00g
  /dev/vdb   vg_root   lvm2 a--  <10.00g      0 
  /dev/vdc   vg_var    lvm2 a--  <10.00g   9.06g
  /dev/vdd   vg_var    lvm2 a--  <10.00g   9.06g
root@ubuntu:~# lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed.
root@ubuntu:~# vgremove /dev/vg_root
  Volume group "vg_root" successfully removed
root@ubuntu:~# pvremove /dev/vdb
  Labels on physical volume "/dev/vdb" successfully wiped.
```

#### Выделить том под /home

Выделяем том под /home по тому же принципу что делали для /var:  
```
root@ubuntu:~# lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.
root@ubuntu:~# mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: e14042fb-cb48-46a6-8975-8c72a5d9e722
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done 

root@ubuntu:~# mount /dev/ubuntu-vg/LogVol_Home /mnt/
root@ubuntu:~# cp -aR /home/* /mnt/
root@ubuntu:~# rm -rf /home/*
root@ubuntu:~# umount /mnt
root@ubuntu:~# mount /dev/ubuntu-vg/LogVol_Home /home/
```

Правим fstab для автоматического монтирования /home:  
```
root@ubuntu:~# echo "`blkid | grep Home | awk '{print $2}'` \
 /home xfs defaults 0 0" >> /etc/fstab
```

#### Работа со снапшотами

Генерируем файлы в /home/:  
```
root@ubuntu:~# touch /home/file{1..20}
```

Снять снапшот:  
```
root@ubuntu:~# lvcreate -L 100MB -s -n home_snap \
 /dev/ubuntu-vg/LogVol_Home
  Logical volume "home_snap" created.
```

Удалить часть файлов:  
```
root@ubuntu:~# rm -f /home/file{11..20}
root@ubuntu:~# ll /home/
total 32
drwxr-xr-x  5 root     root      4096 Jul 16 12:26 ./
drwxr-xr-x 23 root     root      4096 Nov 21  2024 ../
drwxr-x---  3 bazhenov bazhenov  4096 Jul 16 11:51 bazhenov/
-rw-r--r--  1 root     root         0 Jul 16 12:25 file1
-rw-r--r--  1 root     root         0 Jul 16 12:25 file10
-rw-r--r--  1 root     root         0 Jul 16 12:25 file2
-rw-r--r--  1 root     root         0 Jul 16 12:25 file3
-rw-r--r--  1 root     root         0 Jul 16 12:25 file4
-rw-r--r--  1 root     root         0 Jul 16 12:25 file5
-rw-r--r--  1 root     root         0 Jul 16 12:25 file6
-rw-r--r--  1 root     root         0 Jul 16 12:25 file7
-rw-r--r--  1 root     root         0 Jul 16 12:25 file8
-rw-r--r--  1 root     root         0 Jul 16 12:25 file9
drwx------  2 root     root     16384 Jul 16 12:22 lost+found/
drwxr-x---  4 user     user      4096 Nov 21  2024 user/
```

Процесс восстановления из снапшота:  
```
root@ubuntu:~# umount /home
root@ubuntu:~# df -hT 
Filesystem                 Type   Size  Used Avail Use% Mounted on
tmpfs                      tmpfs  392M  1.1M  391M   1% /run
/dev/mapper/ubuntu--vg-lv0 ext4   7.8G  6.0G  1.5G  81% /
tmpfs                      tmpfs  2.0G     0  2.0G   0% /dev/shm
tmpfs                      tmpfs  5.0M     0  5.0M   0% /run/lock
/dev/mapper/vg_var-lv_var  ext4   919M  393M  463M  46% /var
/dev/vda2                  ext4   2.0G   94M  1.7G   6% /boot
tmpfs                      tmpfs  392M   12K  392M   1% /run/user/1001
root@ubuntu:~# lvconvert --merge /dev/ubuntu-vg/home_snap
  Merging of volume ubuntu-vg/home_snap started.
  ubuntu-vg/LogVol_Home: Merged: 100.00%
root@ubuntu:~# mount /dev/mapper/ubuntu--vg-LogVol_Home /home
root@ubuntu:~# ls -al /home
total 32
drwxr-xr-x  5 root     root      4096 Jul 16 12:25 .
drwxr-xr-x 23 root     root      4096 Nov 21  2024 ..
drwxr-x---  3 bazhenov bazhenov  4096 Jul 16 11:51 bazhenov
-rw-r--r--  1 root     root         0 Jul 16 12:25 file1
-rw-r--r--  1 root     root         0 Jul 16 12:25 file10
-rw-r--r--  1 root     root         0 Jul 16 12:25 file11
-rw-r--r--  1 root     root         0 Jul 16 12:25 file12
-rw-r--r--  1 root     root         0 Jul 16 12:25 file13
-rw-r--r--  1 root     root         0 Jul 16 12:25 file14
-rw-r--r--  1 root     root         0 Jul 16 12:25 file15
-rw-r--r--  1 root     root         0 Jul 16 12:25 file16
-rw-r--r--  1 root     root         0 Jul 16 12:25 file17
-rw-r--r--  1 root     root         0 Jul 16 12:25 file18
-rw-r--r--  1 root     root         0 Jul 16 12:25 file19
-rw-r--r--  1 root     root         0 Jul 16 12:25 file2
-rw-r--r--  1 root     root         0 Jul 16 12:25 file20
-rw-r--r--  1 root     root         0 Jul 16 12:25 file3
-rw-r--r--  1 root     root         0 Jul 16 12:25 file4
-rw-r--r--  1 root     root         0 Jul 16 12:25 file5
-rw-r--r--  1 root     root         0 Jul 16 12:25 file6
-rw-r--r--  1 root     root         0 Jul 16 12:25 file7
-rw-r--r--  1 root     root         0 Jul 16 12:25 file8
-rw-r--r--  1 root     root         0 Jul 16 12:25 file9
drwx------  2 root     root     16384 Jul 16 12:22 lost+found
drwxr-x---  4 user     user      4096 Nov 21  2024 user
```
























