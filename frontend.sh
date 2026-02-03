#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD

#-------------------- declaring color code variables-------------------------------#
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#-------------------- checking root user privilages -------------------------------#
if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOG_FILE #using color codes in echo command output
    exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE #using color codes in echo command output
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE #using color codes in echo command output
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disable nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable nginx:1.24 module"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Install nginx:20 module"

systemctl enable nginx 
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "enable and Start nginx service"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "cleaning the html directory"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Download and Unzip forntend"

rm -rf /etc/nginx/nginx.conf 

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our nginx conf file"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted Nginx"