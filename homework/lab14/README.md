# Домашнее задание
## Docker

🎯Задание 
* Установите Docker на хост машину https://docs.docker.com/engine/install/ubuntu/  
* Установите Docker Compose - как плагин, или как отдельное приложение  
* Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)  
* Определите разницу между контейнером и образом  
* Ответьте на вопрос: Можно ли в контейнере собрать ядро?

### Установка Docker

```
apt install -y docker.io docker-compose
```

Создадим папку, в которой будет наш nginx
```
root@ubuntu:/home/bazhenov# mkdir my-nginx-project
root@ubuntu:/home/bazhenov# cd my-nginx-project/
```

Создадим docker-compose.yml:
```
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    image: my-custom-nginx:compose
    container_name: my-nginx-container
    ports:
      - "8080:80"
    restart: always
```

Создадим файл index.html с кастомной строкой приветствия:
```
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <title>Моя кастомная страница</title>
</head>
<body>
    <h1>Привет! Это моя кастомная страница в Nginx на Alpine!</h1>
    <p>Домашнее задание выполнено успешно!</p>
</body>
</html>
```

Создадим dockerfile:
```
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html 
```

Запустим контейнер:
```
root@ubuntu:/home/bazhenov/my-nginx-project# docker-compose up -d
Building web
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon   5.12kB
Step 1/2 : FROM nginx:alpine
alpine: Pulling from library/nginx
90de1d15efe2: Pulling fs layer
e2de96513ba9: Pulling fs layer
fb08ee61b60d: Pulling fs layer
ce3e77cbba4d: Pulling fs layer
cb2f2cc9a341: Pulling fs layer
873bdb7a78a1: Pulling fs layer
c0ac6b3b9c77: Pulling fs layer
f408df9a891a: Pulling fs layer
9d8ea080e87f: Download complete
ec6129a9436d: Download complete
ce3e77cbba4d: Download complete
873bdb7a78a1: Download complete
f408df9a891a: Download complete
cb2f2cc9a341: Download complete
c0ac6b3b9c77: Download complete
fb08ee61b60d: Download complete
e2de96513ba9: Download complete
e2de96513ba9: Pull complete
ce3e77cbba4d: Pull complete
fb08ee61b60d: Pull complete
873bdb7a78a1: Pull complete
f408df9a891a: Pull complete
cb2f2cc9a341: Pull complete
c0ac6b3b9c77: Pull complete
90de1d15efe2: Download complete
90de1d15efe2: Pull complete
Digest: sha256:62ff2089abf5a9ed33bd232895bef5e22f7bb4b200675cec49a5ebc48e3d4ac8
Status: Downloaded newer image for nginx:alpine
 ---> 62ff2089abf5
Step 2/2 : COPY index.html /usr/share/nginx/html/index.html
 ---> 6dbcf80869cb
Successfully built 6dbcf80869cb
Successfully tagged my-custom-nginx:compose
WARNING: Image for service web was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
Creating my-nginx-container ... done
root@ubuntu:/home/bazhenov/my-nginx-project#
```

Проверим результат:
![Alt text](https://github.com/bislogin/OTUS_Linux_Prof/blob/main/homework/lab14/docker.png)


### Разница между контейнером и образом   
* Образ (Image): Неизменяемый (read-only) шаблон и «слепок» файловой системы, содержащий ОС, код и зависимости.   
* Контейнер (Container): Запущенный и изолированный процесс на основе образа с динамическим слоем записи.
Образ — это рецепт, а контейнер — готовое к работе приложение.

### Можно ли в контейнере собрать ядро?
Да, скомпилировать ядро внутри контейнера можно, так как это стандартный процесс сборки, требующий лишь компилятора и исходников.    
Однако запустить его на хосте напрямую не получится, поскольку контейнеры используют общее ядро хост-системы.
