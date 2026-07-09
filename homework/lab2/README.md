# Домашнее задание
## Работа с mdadm


🎯Задание

• Добавить в виртуальную машину несколько дисков  
• Собрать RAID-0/1/5/10 на выбор  
• Сломать и починить RAID  
• Создать GPT таблицу, пять разделов и смонтировать их в системе.  



### Собрать RAID-0/1/5/10 — на выбор

Посмотрим, какие блочные устройства у нас есть:  
```
root@ubuntu:/home/bazhenov# sudo fdisk -l
Disk /dev/vda: 40 GiB, 42949672960 bytes, 83886080 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: EDF61F04-C251-422A-BA40-13A351F2C549

Device       Start      End  Sectors Size Type
/dev/vda1     2048     4095     2048   1M BIOS boot
/dev/vda2     4096  4198399  4194304   2G Linux filesystem
/dev/vda3  4198400 83884031 79685632  38G Linux filesystem


Disk /dev/vdb: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdc: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdd: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/ubuntu--vg-lv0: 38 GiB, 40797995008 bytes, 79683584 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

Создадим рейд следующей командой:

```
root@ubuntu:/home/bazhenov# mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/vd{b,c}
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
mdadm: size set to 10476544K
Continue creating array? 
Continue creating array? (y/n) y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

Проверим, что RAID собрался нормально:

```
root@ubuntu:/home/bazhenov# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid1 vdc[1] vdb[0]
      10476544 blocks super 1.2 [2/2] [UU]
      
unused devices: <none>
```

```
root@ubuntu:/home/bazhenov# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Thu Jul  9 05:08:18 2026
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Jul  9 05:09:11 2026
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : ubuntu:0  (local to host ubuntu)
              UUID : 2da4a261:075634c3:1f7c7c32:a56a7987
            Events : 17

    Number   Major   Minor   RaidDevice State
       0     253       16        0      active sync   /dev/vdb
       1     253       32        1      active sync   /dev/vdc
```

### Сломать и починить RAID

Искусственно “зафейлим” одно из блочных устройств командной:

```
root@ubuntu:/home/bazhenov# mdadm /dev/md0 --fail /dev/vdb
mdadm: set /dev/vdb faulty in /dev/md0
```

Посмотрим, как это отразилось на RAID:

```
root@ubuntu:/home/bazhenov# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid1 vdc[1] vdb[0](F)
      10476544 blocks super 1.2 [2/1] [_U]
      
unused devices: <none>
```

```
root@ubuntu:/home/bazhenov# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Thu Jul  9 05:08:18 2026
        Raid Level : raid1
        Array Size : 10476544 (9.99 GiB 10.73 GB)
     Used Dev Size : 10476544 (9.99 GiB 10.73 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Jul  9 05:14:58 2026
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : ubuntu:0  (local to host ubuntu)
              UUID : 2da4a261:075634c3:1f7c7c32:a56a7987
            Events : 19

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1     253       32        1      active sync   /dev/vdc

       0     253       16        -      faulty   /dev/vdb
```

Удалим “сломанный” диск из массива:

```
root@ubuntu:/home/bazhenov# mdadm /dev/md0 --remove /dev/vdb
mdadm: hot removed /dev/vdb from /dev/md0
```

Представим, что мы вставили новый диск в сервер и теперь нам нужно добавить его в RAID. Делается это так:

```
root@ubuntu:/home/bazhenov# mdadm /dev/md0 --add /dev/vdd
mdadm: added /dev/vdd
```

Диск должен пройти стадию rebuilding.

```
root@ubuntu:/home/bazhenov# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md0 : active raid1 vdd[2] vdc[1]
      10476544 blocks super 1.2 [2/1] [_U]
      [=================>...]  recovery = 88.7% (9294208/10476544) finish=0.0min speed=206116K/sec
      
unused devices: <none>
```

### Создать GPT таблицу, пять разделов и смонтировать их в системе

Создаем раздел GPT на RAID

```
root@ubuntu:/home/bazhenov# parted -s /dev/md0 mklabel gpt
```

Создаем партиции

```
root@ubuntu:/home/bazhenov# parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

root@ubuntu:/home/bazhenov# parted /dev/md0 mkpart primary ext4 20% 40%   
Information: You may need to update /etc/fstab.

root@ubuntu:/home/bazhenov# parted /dev/md0 mkpart primary ext4 40% 60%   
Information: You may need to update /etc/fstab.

root@ubuntu:/home/bazhenov# parted /dev/md0 mkpart primary ext4 60% 80%   
Information: You may need to update /etc/fstab.

root@ubuntu:/home/bazhenov# parted /dev/md0 mkpart primary ext4 80% 100%  
Information: You may need to update /etc/fstab.

```

Далее можно создать на этих партициях ФС

```
root@ubuntu:/home/bazhenov# for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 523520 4k blocks and 131072 inodes
Filesystem UUID: 5878a7b5-9df4-4069-a75b-8f187770ce69
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 523776 4k blocks and 131072 inodes
Filesystem UUID: 6a08c81c-add5-466a-a04c-4ba0c1a15d54
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 524032 4k blocks and 131072 inodes
Filesystem UUID: d2022f41-cb35-40be-92cd-3a9be4dca1e6
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 523776 4k blocks and 131072 inodes
Filesystem UUID: 6e8a3a4d-87e7-4318-8de8-6b59e69a75be
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done                            
Creating filesystem with 523520 4k blocks and 131072 inodes
Filesystem UUID: a401aa53-fa4a-4036-bb48-64847d6f6f2c
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done 

```

И смонтировать их по каталогам

```
root@ubuntu:/home/bazhenov# mkdir -p /raid/part{1,2,3,4,5}
root@ubuntu:/home/bazhenov# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```

```
root@ubuntu:/home/bazhenov# sudo fdisk -l
Disk /dev/vda: 40 GiB, 42949672960 bytes, 83886080 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: EDF61F04-C251-422A-BA40-13A351F2C549

Device       Start      End  Sectors Size Type
/dev/vda1     2048     4095     2048   1M BIOS boot
/dev/vda2     4096  4198399  4194304   2G Linux filesystem
/dev/vda3  4198400 83884031 79685632  38G Linux filesystem


Disk /dev/vdb: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdc: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/vdd: 10 GiB, 10737418240 bytes, 20971520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/mapper/ubuntu--vg-lv0: 38 GiB, 40797995008 bytes, 79683584 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/md0: 9.99 GiB, 10727981056 bytes, 20953088 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: E25729F1-5129-4244-A8D3-8CEFFFB8D56F

Device        Start      End Sectors Size Type
/dev/md0p1     2048  4190207 4188160   2G Linux filesystem
/dev/md0p2  4190208  8380415 4190208   2G Linux filesystem
/dev/md0p3  8380416 12572671 4192256   2G Linux filesystem
/dev/md0p4 12572672 16762879 4190208   2G Linux filesystem
/dev/md0p5 16762880 20951039 4188160   2G Linux filesystem
```

Добавим все разделы в fstab

```
for i in $(seq 1 5); do echo "UUID=$(blkid -o value -s UUID /dev/md0p$i) /raid/part$i ext4 defaults 0 2" >> /etc/fstab; done
```
