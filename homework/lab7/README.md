# Домашнее задание
## Работа с загрузчиком


🎯Задание
1. Включить отображение меню Grub.   
2. Попасть в систему без пароля несколькими способами.   
3. Установить систему с LVM, после чего переименовать VG.

### Включить отображение меню Grub   

По умолчанию меню загрузчика Grub скрыто и нет задержки при загрузке. Для отображения меню нужно отредактировать конфигурационный файл.   
```
root@ubuntu22:~# nano /etc/default/grub
```

Комментируем строку, скрывающую меню и ставим задержку для выбора пункта меню в 10 секунд.   
```
#GRUB_TIMEOUT_STYLE=hidden
GRUB_TIMEOUT=10

```

Обновляем конфигурацию загрузчика и перезагружаемся для проверки.   
```
root@ubuntu:/# update-grub
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.8.0-136-generic
Found initrd image: /boot/initrd.img-6.8.0-136-generic
Found linux image: /boot/vmlinuz-6.8.0-49-generic
Found initrd image: /boot/initrd.img-6.8.0-49-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done
root@ubuntu:/# reboot
```

При загрузке в окне виртуальной машины мы должны увидеть меню загрузчика.


<img src="https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab7/grub.png" />  

### Попасть в систему без пароля несколькими способами   

Для получения доступа необходимо открыть GUI VirtualBox (или другой системы виртуализации), запустить виртуальную машину и при выборе ядра для загрузки нажать e - в данном контексте edit. Попадаем в окно, где мы можем изменить параметры загрузки:  

<img src="https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab7/grub2.png" />  

#### Способ 1. init=/bin/bash

В конце строки, начинающейся с linux, добавляем init=/bin/bash и нажимаем сtrl-x для загрузки в систему
В целом на этом все, Вы попали в систему. Но есть один нюанс. Рутовая файловая
система при этом монтируется в режиме Read-Only. Если вы хотите перемонтировать ее в режим Read-Write, можно воспользоваться командой:
```
root@ubuntu:/# mount -o remount,rw /
```


После чего можно убедиться, записав данные в любой файл или прочитав вывод
команды:


<img src="https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab7/grub3.png" />  

#### Способ 2. Recovery mode

В меню загрузчика на первом уровне выбрать второй пункт (Advanced options…), далее загрузить пункт меню с указанием recovery mode в названии.    
Получим меню режима восстановления.   

<img src="https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab7/grub4.png" />  

В этом меню сначала включаем поддержку сети (network) для того, чтобы файловая система перемонтировалась в режим read/write (либо это можно сделать вручную).
Далее выбираем пункт root и попадаем в консоль с пользователем root. Если ранее был устанавлен пароль для пользователя root (по умолчанию его нет), то необходимо его ввести. 
В этой консоли можно производить любые манипуляции с системой.


### Установить систему с LVM, после чего переименовать VG  

Мы установили систему Ubuntu со стандартной разбивкой диска с использованием  LVM.  
Первым делом посмотрим текущее состояние системы (список Volume Group):  
```
root@ubuntu:~# vgs
  VG        #PV #LV #SN Attr   VSize   VFree
  ubuntu-vg   1   1   0 wz--n- <38.00g    0 
```

Нас интересует вторая строка с именем **Volume Group**. Приступим к переименованию:  
```
root@ubuntu:~# vgrename ubuntu-vg ubuntu-otus
  Volume group "ubuntu-vg" successfully renamed to "ubuntu-otus"
```

Далее правим **/boot/grub/grub.cfg**. Везде заменяем старое название **VG** на новое (в файле дефис меняется на два дефиса **ubuntu--vg ubuntu--otus**).
После чего можем перезагружаться и, если все сделано правильно, успешно грузимся с новым именем **Volume Group** и проверяем:
```
root@ubuntu:~# vgs
  VG          #PV #LV #SN Attr   VSize   VFree
  ubuntu-otus   1   1   0 wz--n- <38.00g    0 
```

При желании можно так же заменить название **Logical Volume**.
