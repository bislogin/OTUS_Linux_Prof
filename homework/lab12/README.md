# Домашнее задание
## Первые шаги с Ansible

🎯Задание    

Подготовить стенд как минимум с одним сервером. На этом сервере, используя Ansible, необходимо развернуть nginx со следующими условиями:  

* необходимо использовать модуль yum/apt;
* конфигурационные файлы должны быть взяты из шаблона jinja2 с переменными;
* после установки nginx должен быть в режиме enabled в systemd;
* должен быть использован notify для старта nginx после установки;
* сайт должен слушать на нестандартном порту — 8080, для этого использовать переменные в Ansible.

Перед началом установим ansible
```
root@ubuntu:/home# apt install ansible
root@ubuntu:/home# ansible --version
ansible [core 2.16.3]
  config file = None
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.3 (main, Jun 19 2026, 12:46:00) [GCC 13.3.0] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
```

Создадим файл hosts.ini и укажем там наш хост:
```
root@ubuntu:/home/ansible# nano hosts.ini 
  GNU nano 7.2                                                                                                    hosts.ini                                                                                                              
[web]
172.20.1.20
```

Создадим файл ansible.cfg и укажем там наш inventory, чтобы не указывать каждый раз.
```
root@ubuntu:/home/ansible# nano ansible.cfg 
  GNU nano 7.2                                                                                                   ansible.cfg                                                                                                             
[defaults]
inventory = hosts.ini
```

Создаем папку nginx со следующими файлами:
```
root@ubuntu:/home/ansible/nginx# tree 
.
├── hosts.ini
├── playbook.yml
└── templates
    └── nginx.conf.j2

2 directories, 3 files
```
В файле playbook.yml прописываем:
```
  GNU nano 7.2                                                                                                   playbook.yml                                                                                                            
---
- name: install nginx
  hosts: web
  become: true
  vars:
    nginx_listen_port: 8080

  tasks:
    - name: update
      apt:
        update_cache=yes
      tags:
        - update apt

    - name: install nginx
      apt:
        name: nginx
        state: latest
      notify:
        - restart nginx
      tags:
        - nginx-packege

    - name: config nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify:
        - reload nginx
      tags:
        - nginx-config

  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
        enabled: yes

    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded

```

В файле nginx.conf.j2:
```
# {{ ansible_managed }}
events {
    worker_connections 1024;
}

http {
    server {
        listen       {{ nginx_listen_port }} default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}

```

Запускаем наш плейбук:
```
root@ubuntu:/home/ansible# ansible-playbook nginx/playbook.yml 

PLAY [install nginx] ********************************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************************************
ok: [172.20.1.20]

TASK [update] ***************************************************************************************************************************************************************************************************************************
changed: [172.20.1.20]

TASK [install nginx] ********************************************************************************************************************************************************************************************************************
ok: [172.20.1.20]

TASK [config nginx] *********************************************************************************************************************************************************************************************************************
changed: [172.20.1.20]

RUNNING HANDLER [reload nginx] **********************************************************************************************************************************************************************************************************
changed: [172.20.1.20]

PLAY RECAP ******************************************************************************************************************************************************************************************************************************
172.20.1.20                : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

root@ubuntu:/home/ansible# 
```

Проверим, зайдем на 172.20.1.20:8080

![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab12/ansible.png)
