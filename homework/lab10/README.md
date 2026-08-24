# Домашнее задание
## Управление процессами


🎯Задание   
Реализация аналога ps ax   

* Создайте скрипт, который получает информацию о процессах через файловую систему /proc.
* Реализуйте вывод не менее следующих полей: PID, PPID, состояние процесса, имя или команда запуска.
* Проверьте работу скрипта на запущенной системе.
* Зафиксируйте пример результата работы.


```
#!/bin/bash

# Print the table header with wide spacing for the full command
printf "%-7s %-7s %-8s %s\n" "PID" "PPID" "STATUS" "COMMAND_LINE"
echo "--------------------------------------------------------"

# Iterate through all directories in /proc that consist only of numbers
for pid_dir in /proc/[0-9]*/; do
    # Extract the PID from the directory path
    pid=$(basename "$pid_dir")

    # Check if the stat file exists (the process might have terminated)
    if [ ! -f "${pid_dir}stat" ]; then
        continue
    fi

    # Read the process state ($3) and PPID ($4) from the stat file
    read -r state ppid <<< "$(awk '{print $3, $4}' "${pid_dir}stat")"

    # Read the command line arguments (replace null bytes with spaces)
    if [ -s "${pid_dir}cmdline" ]; then
        # xargs removes trailing whitespaces and formats it nicely
        cmd=$(tr '\0' ' ' < "${pid_dir}cmdline" | xargs)
    else
        # If cmdline is empty (kernel thread), get the name from stat brackets
        cmd="[$(awk -F'(' '{print $2}' "${pid_dir}stat" | awk -F')' '{print $1}')]"
    fi

    # Print the formatted table row (command is not truncated anymore)
    printf "%-7s %-7s %-8s %s\n" "$pid" "$ppid" "$state" "$cmd"
done

```

Проверяем работу скрипта:
```
root@ubuntu:/home# ./my_ps.sh
PID     PPID    STATUS   COMMAND_LINE
--------------------------------------------------------
1       0       S        [systemd]
11      2       I        [kworker/R-mm_pe]
12      2       I        [rcu_tasks_kthread]
13      2       I        [rcu_tasks_rude_kthread]
14      2       I        [rcu_tasks_trace_kthread]
15      2       S        [ksoftirqd/0]
166     2       I        [kworker/R-ttm]
17      2       I        [rcu_preempt]
17374   2       I        [kworker/u4:1-ext4-rsv-conversion]
18      2       S        [migration/0]
19      2       S        [idle_inject/0]
190     2       I        [kworker/R-kdmfl]
2       0       S        [kthreadd]
20      2       S        [cpuhp/0]
20529   2       I        [kworker/0:0H-kblockd]
2093    2       I        [kworker/R-tls-s]
21      2       S        [cpuhp/1]
21276   1       S        [sshd]
21281   1       S        [systemd]
21284   21281   S        []
21392   21276   S        [sshd]
21393   21392   S        [bash]
216     2       I        [kworker/R-raid5]
22      2       S        [idle_inject/1]
23      2       S        [migration/1]
24      2       S        [ksoftirqd/1]
256     2       S        [jbd2/dm-0-8]
257     2       I        [kworker/R-ext4-]
26      2       I        [kworker/1:0H-kblockd]
29      2       S        [kdevtmpfs]
3       2       S        [pool_workqueue_release]
30      2       I        [kworker/R-inet_]
30712   1       S        [htcacheclean]
30946   21393   S        [sudo]
30952   30946   S        [sudo]
30953   30952   S        [bash]
31      2       S        [kauditd]
31029   1       S        [php-cgi]
31030   31029   S        [php-cgi]
31031   31029   S        [php-cgi]
31032   31029   S        [php-cgi]
31033   31029   S        [php-cgi]
31034   31029   S        [php-cgi]
31035   31029   S        [php-cgi]
31036   31029   S        [php-cgi]
31037   31029   S        [php-cgi]
31038   31029   S        [php-cgi]
31039   31029   S        [php-cgi]
31040   31029   S        [php-cgi]
31041   31029   S        [php-cgi]
31042   31029   S        [php-cgi]
31043   31029   S        [php-cgi]
31044   31029   S        [php-cgi]
31045   31029   S        [php-cgi]
31046   31029   S        [php-cgi]
31047   31029   S        [php-cgi]
31048   31029   S        [php-cgi]
31049   31029   S        [php-cgi]
31050   31029   S        [php-cgi]
31051   31029   S        [php-cgi]
31052   31029   S        [php-cgi]
31053   31029   S        [php-cgi]
31054   31029   S        [php-cgi]
31055   31029   S        [php-cgi]
31056   31029   S        [php-cgi]
31057   31029   S        [php-cgi]
31058   31029   S        [php-cgi]
31059   31029   S        [php-cgi]
31060   31029   S        [php-cgi]
31061   31029   S        [php-cgi]
32      2       S        [khungtaskd]
33      2       S        [oom_reaper]
33223   30953   T        [sudo]
33224   33223   S        [sudo]
33225   33224   T        [crontab]
33226   33225   T        [sh]
33227   33226   T        [sensible-editor]
33230   33227   T        [select-editor]
35      2       I        [kworker/R-write]
353     2       I        [kworker/R-kmpat]
354     2       I        [kworker/R-kmpat]
363627  2       I        [kworker/u4:2-ext4-rsv-conversion]
37      2       S        [kcompactd0]
379948  1       S        [systemd-network]
379968  1       S        [systemd-journal]
38      2       S        [ksmd]
380045  1       S        [systemd-timesyn]
380122  1       S        [systemd-udevd]
380128  2       S        [psimon]
380199  1       S        [systemd-resolve]
384835  1       S        [rpcbind]
384844  1       S        [multipathd]
384851  1       S        [upowerd]
384857  1       S        [polkitd]
384858  1       S        [udisksd]
384873  1       S        [sshd]
384909  1       S        [ModemManager]
384912  1       S        [apache2]
384913  1       S        [rsyslogd]
4       2       I        [kworker/R-rcu_g]
40      2       S        [khugepaged]
41      2       I        [kworker/R-kinte]
42      2       I        [kworker/R-kbloc]
43      2       I        [kworker/R-blkcg]
44      2       S        [irq/9-acpi]
45      2       I        [kworker/R-tpm_d]
46      2       I        [kworker/R-ata_s]
47      2       I        [kworker/R-md]
48      2       I        [kworker/R-md_bi]
484     2       S        [jbd2/vda2-8]
485     2       I        [kworker/R-ext4-]
49      2       I        [kworker/R-edac-]
5       2       I        [kworker/R-rcu_p]
50      2       I        [kworker/R-devfr]
51      2       S        [watchdogd]
52      2       I        [kworker/R-quota]
54      2       I        [kworker/1:1H]
55      2       S        [kswapd0]
56      2       S        [ecryptfs-kthread]
57      2       I        [kworker/R-kthro]
58      2       I        [kworker/R-acpi_]
587     2       I        [kworker/R-rpcio]
588     2       I        [kworker/R-xprti]
591     2       I        [kworker/R-cfg80]
6       2       I        [kworker/R-slub_]
60      2       S        [scsi_eh_0]
600529  2       S        [psimon]
600602  1       S        [nginx]
600603  600602  S        [nginx]
600604  600602  S        [nginx]
600606  1       S        [nginx]
600607  600606  S        [nginx]
600609  600606  S        [nginx]
604753  2       I        [kworker/0:1H]
61      2       I        [kworker/R-scsi_]
62      2       S        [scsi_eh_1]
63      2       I        [kworker/R-scsi_]
65      2       I        [kworker/R-mld]
658657  384912  S        [apache2]
658658  384912  S        [apache2]
658659  384912  S        [apache2]
658660  384912  S        [apache2]
658661  384912  S        [apache2]
658662  384912  S        [apache2]
66      2       I        [kworker/R-ipv6_]
660181  2       I        [kworker/0:2-cgroup_release]
662445  2       I        [kworker/1:2-events]
662473  2       I        [kworker/u6:2-events_power_efficient]
662565  2       I        [kworker/u5:4-events_power_efficient]
662814  2       I        [kworker/u5:0-events_power_efficient]
664644  2       I        [kworker/u6:1-events_unbound]
664673  2       I        [kworker/0:1-events]
665586  2       I        [kworker/u6:0-events_unbound]
668399  2       I        [kworker/1:0-cgroup_release]
668465  2       I        [kworker/u5:2-events_power_efficient]
668472  2       I        [kworker/u5:3-events_power_efficient]
671205  1       S        [packagekitd]
671395  2       I        [kworker/0:0-cgroup_release]
671411  2       I        [kworker/1:1-cgroup_free]
671423  2       I        [kworker/u6:3-events_unbound]
671429  30953   S        [my_ps.sh]
696     2       I        [kworker/R-nfit]
7       2       I        [kworker/R-netns]
717     1       S        [dbus-daemon]
727     1       S        [systemd-logind]
74      2       I        [kworker/R-kstrp]
755     1       S        [cron]
77      2       I        [kworker/u7:0]
78      2       I        [kworker/u8:0]
785     1       S        [unattended-upgr]
79      2       I        [kworker/u9:0]
813     1       S        [agetty]
84      2       I        [kworker/R-crypt]
95      2       I        [kworker/R-charg]
```
