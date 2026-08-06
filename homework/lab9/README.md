# Домашнее задание
## bash-скрипт


🎯Задание   
написать bash-скрипт, который ежечасно формирует и отправляет на email отчёт о работе веб-сервера  

Так как почтовый сервер не настроен(и ещё не проходили), и предоставленный кусок assess.log содержит не актуальное время, отчет будет просто проверять весь лог и результат записываться в файл.   

Создадим файл test_report.sh:   
```
#!/bin/bash

# CONFIGURATION FOR TESTING
LOG_FILE="/var/log/nginx/access.log"

# Check if the log file exists and is not empty
if [ ! -s "$LOG_FILE" ]; then
    echo "Error: Test log file is empty or does not exist."
    exit 1
fi

# Function to parse date from the log just to display the timeframe of the file
# Extracts the first and the last line dates
FIRST_LINE_DATE=$(head -n 1 "$LOG_FILE" | awk '{print $4}' | tr -d '[]')
LAST_LINE_DATE=$(tail -n 1 "$LOG_FILE" | awk '{print $4}' | tr -d '[]')

# Generate the report content and output directly to the terminal
echo "==============================================================================="
echo " TEST WEB SERVER REPORT (ALL LOG ENTRIES PROCESSED)"
echo " Log file timeframe: From $FIRST_LINE_DATE to $LAST_LINE_DATE"
echo " Generated at: $(date +"%Y-%m-%d %H:%M:%S")"
echo "==============================================================================="
echo ""

echo "--- TOP 10 IP ADDRESSES WITH THE MOST REQUESTS ---"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 10
echo ""

echo "--- TOP 10 REQUESTED URLS ---"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 10
echo ""

echo "--- HTTP RESPONSE CODES SUMMARY ---"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -rn
echo ""

echo "--- WEB SERVER AND APPLICATION ERRORS (4xx and 5xx Codes) ---"
# Фильтруем 9-й столбец (код ответа) на наличие цифр 4 или 5 в начале
awk '$9 ~ /^[45]/ {print "Code: " $9 " | URL: " $7 " | IP: " $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 20
echo ""

```

Даем права на выполнения, и запускаем скрипт:   
```
root@ubuntu:/home# chmod +x test_report.sh 
root@ubuntu:/home# ./test_report.sh 
===============================================================================
 TEST WEB SERVER REPORT (ALL LOG ENTRIES PROCESSED)
 Log file timeframe: From 14/Aug/2019:04:12:10 to 15/Aug/2019:00:25:46
 Generated at: 2026-08-06 15:53:14
===============================================================================

--- TOP 10 IP ADDRESSES WITH THE MOST REQUESTS ---
     45 93.158.167.130
     39 109.236.252.130
     37 212.57.117.19
     33 188.43.241.106
     31 87.250.233.68
     24 62.75.198.172
     22 148.251.223.21
     20 185.6.8.9
     17 217.118.66.161
     16 95.165.18.146

--- TOP 10 REQUESTED URLS ---
    157 /
    120 /wp-login.php
     57 /xmlrpc.php
     26 /robots.txt
     12 /favicon.ico
     11 400
      9 /wp-includes/js/wp-embed.min.js?ver=5.0.4
      7 /wp-admin/admin-post.php?page=301bulkoptions
      7 /1
      6 /wp-content/uploads/2016/10/robo5.jpg

--- HTTP RESPONSE CODES SUMMARY ---
    498 200
     95 301
     51 404
     11 "-"
      7 400
      3 500
      2 499
      1 405
      1 403
      1 304

--- WEB SERVER AND APPLICATION ERRORS (4xx and 5xx Codes) ---
     11 Code: 404 | URL: / | IP: 93.158.167.130
     10 Code: 404 | URL: / | IP: 87.250.233.68
      3 Code: 404 | URL: / | IP: 5.45.203.12
      3 Code: 404 | URL: / | IP: 141.8.141.136
      2 Code: 404 | URL: /robots.txt | IP: 77.247.110.165
      2 Code: 404 | URL: / | IP: 87.250.233.76
      2 Code: 404 | URL: /1 | IP: 62.210.252.196
      2 Code: 404 | URL: /1 | IP: 162.243.13.195
      2 Code: 400 | URL: /wp-admin/admin-ajax.php?page=301bulkoptions | IP: 62.210.252.196
      2 Code: 400 | URL: /wp-admin/admin-ajax.php?page=301bulkoptions | IP: 162.243.13.195
      1 Code: 500 | URL: /wp-includes/ID3/comay.php | IP: 193.106.30.99
      1 Code: 500 | URL: /wp-content/uploads/2018/08/seo_script.php | IP: 193.106.30.99
      1 Code: 500 | URL: /wp-content/plugins/uploadify/includes/check.php | IP: 107.179.102.58
      1 Code: 499 | URL: /wp-cron.php?doing_wp_cron=1565803543.6812090873718261718750 | IP: 62.75.198.172
      1 Code: 499 | URL: /wp-cron.php?doing_wp_cron=1565760219.4257180690765380859375 | IP: 62.75.198.172
      1 Code: 405 | URL: / | IP: 182.254.243.249
      1 Code: 404 | URL: /wp-content/plugins/uploadify/readme.txt | IP: 107.179.102.58
      1 Code: 404 | URL: /.well-known/security.txt | IP: 71.6.199.23
      1 Code: 404 | URL: /.well-known/security.txt | IP: 185.142.236.35
      1 Code: 404 | URL: /webdav/ | IP: 182.254.243.249

```
