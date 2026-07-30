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

https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab7/grub.png

При загрузке в окне виртуальной машины мы должны увидеть меню загрузчика.

