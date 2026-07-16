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











