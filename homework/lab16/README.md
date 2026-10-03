# Домашнее задание
## PAM

🎯Задание 
Ограничить доступ к системе для всех пользователей, кроме группы администраторов, в выходные дни (суббота и воскресенье), за исключением праздничных дней.


Переходим в root-пользователя: sudo -i   
Создаём пользователя otusadm и otus
```
root@ubuntu:/home/bazhenov# useradd otusadm && useradd otus
```

Создаём пользователям пароли:
```
root@ubuntu:/home/bazhenov# echo "otusadm:Otus2022!" | chpasswd && echo "otus:Otus2022!" | chpasswd
```

Создаём группу admin:
```
root@ubuntu:/home/bazhenov# groupadd -f admin
```

Добавляем пользователей root и otusadm в группу admin:
```
root@ubuntu:/home/bazhenov# usermod otusadm -a -G admin && usermod root -a -G admin
```

После создания пользователей, нужно проверить, что они могут подключаться по SSH к нашей ВМ. Для этого пытаемся подключиться с хостовой машины: 
```
root@ubuntu:/home/bazhenov# ssh otus@172.20.1.20
otus@172.20.1.20's password: 
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 6.8.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Oct  3 01:11:34 PM UTC 2026

  System load:  0.13               Processes:             167
  Usage of /:   34.9% of 37.10GB   Users logged in:       1
  Memory usage: 22%                IPv4 address for ens3: 172.20.1.20
  Swap usage:   0%

 * Canonical Workshop gives developers fast, composable, reproducible, and
   secure developer environments that are perfect for agentic workflows.

   https://ubuntu.com/workshop

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

3 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm


*** System restart required ***

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

Could not chdir to home directory /home/otus: No such file or directory
$ exit
Connection to 172.20.1.20 closed.
root@ubuntu:/home/bazhenov# 
root@ubuntu:/home/bazhenov# ssh otusadm@172.20.1.20
otusadm@172.20.1.20's password: 
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 6.8.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Oct  3 01:11:34 PM UTC 2026

  System load:  0.13               Processes:             167
  Usage of /:   34.9% of 37.10GB   Users logged in:       1
  Memory usage: 22%                IPv4 address for ens3: 172.20.1.20
  Swap usage:   0%

 * Canonical Workshop gives developers fast, composable, reproducible, and
   secure developer environments that are perfect for agentic workflows.

   https://ubuntu.com/workshop

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

3 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm

New release '26.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


*** System restart required ***

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

Could not chdir to home directory /home/otusadm: No such file or directory
$ exit
Connection to 172.20.1.20 closed.
root@ubuntu:/home/bazhenov# 
```

Далее настроим правило, по которому все пользователи кроме тех, что указаны в группе admin не смогут подключаться в выходные дни:
```
root@ubuntu:/home/bazhenov# cat /etc/group | grep admin
admin:x:1004:otusadm,root
```

Создадим файл-скрипт /usr/local/bin/login.sh

```
#!/bin/bash
#Первое условие: если день недели суббота или воскресенье
if [ $(date +%a) = "Sat" ] || [ $(date +%a) = "Sun" ]; then
 #Второе условие: входит ли пользователь в группу admin
 if getent group admin | grep -qw "$PAM_USER"; then
        #Если пользователь входит в группу admin, то он может подключиться
        exit 0
      else
        #Иначе ошибка (не сможет подключиться)
        exit 1
    fi
  #Если день не выходной, то подключиться может любой пользователь
  else
    exit 0
fi
```

В скрипте подписаны все условия. Скрипт работает по принципу:    
Если сегодня суббота или воскресенье, то нужно проверить, входит ли пользователь в группу admin, если не входит — то подключение запрещено. При любых других вариантах подключение разрешено. 

Добавим права на исполнение файла:
```
root@ubuntu:/home/bazhenov# chmod +x /usr/local/bin/login.sh
```

 Укажем в файле /etc/pam.d/sshd модуль pam_exec и наш скрипт:
```
root@ubuntu:/home/bazhenov# nano /etc/pam.d/sshd
                                                                                              /etc/pam.d/sshd                                                                                                           
# PAM configuration for the Secure Shell service

auth required pam_exec.so debug /usr/local/bin/login.sh

# Standard Un*x authentication.
@include common-auth

# Disallow non-root logins when /etc/nologin exists.
account    required     pam_nologin.so

# Uncomment and edit /etc/security/access.conf if you need to set complex
# access limits that are hard to express in sshd_config.
# account  required     pam_access.so

# Standard Un*x authorization.
@include common-account

# SELinux needs to be the first session rule.  This ensures that any
# lingering context has been cleared.  Without this it is possible that a
# module could execute code in the wrong domain.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so close

# Set the loginuid process attribute.
session    required     pam_loginuid.so

# Create a new session keyring.
session    optional     pam_keyinit.so force revoke

# Standard Un*x session setup and teardown.
@include common-session

# Print the message of the day upon successful login.
# This includes a dynamically generated part from /run/motd.dynamic
# and a static (admin-editable) part from /etc/motd.
session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate

# Print the status of the user's mailbox upon successful login.
session    optional     pam_mail.so standard noenv # [1]

# Set up user limits from /etc/security/limits.conf.
session    required     pam_limits.so

# Read environment variables from /etc/environment and
# /etc/security/pam_env.conf.
session    required     pam_env.so # [1]
# In Debian 4.0 (etch), locale-related environment variables were moved to
# /etc/default/locale, so read that as well.
session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale

# SELinux needs to intervene at login time to ensure that the process starts
# in the proper default security context.  Only sessions which are intended
# to run in the user's context should be run after this.
session [success=ok ignore=ignore module_unknown=ignore default=bad]        pam_selinux.so open

# Standard Un*x password updating.
@include common-password

```

Пробуем ещё раз подключиться:
```
root@ubuntu:/home/bazhenov# ssh otus@172.20.1.20
otus@172.20.1.20's password: 
Permission denied, please try again.
otus@172.20.1.20's password: 
Permission denied, please try again.
otus@172.20.1.20's password: 
otus@172.20.1.20: Permission denied (publickey,password).
root@ubuntu:/home/bazhenov# ssh otusadm@172.20.1.20
otusadm@172.20.1.20's password: 
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 6.8.0-139-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Oct  3 01:19:05 PM UTC 2026

  System load:  0.16               Processes:             168
  Usage of /:   34.9% of 37.10GB   Users logged in:       1
  Memory usage: 21%                IPv4 address for ens3: 172.20.1.20
  Swap usage:   0%

 * Canonical Workshop gives developers fast, composable, reproducible, and
   secure developer environments that are perfect for agentic workflows.

   https://ubuntu.com/workshop

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

3 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm

New release '26.04.1 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


*** System restart required ***

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

Last login: Sat Oct  3 13:12:01 2026 from 172.20.1.20
Could not chdir to home directory /home/otusadm: No such file or directory
$ exit
Connection to 172.20.1.20 closed.
root@ubuntu:/home/bazhenov# 
```
