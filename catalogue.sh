#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOG_FILES="$LOGS_FOLDER/$0.log"
MONGO_HOST="mongodb.techno90s.online"

#-------------------- declaring color code variables-------------------------------#
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#-------------------- checking root user privilages -------------------------------#
if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE #using color codes in echo command output
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE #using color codes in echo command output
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE #using color codes in echo command output
    fi
}

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "disable nodejs module"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "enable nodejs:20 module"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Install nodejs:20 module"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop tee -a $LOGS_FILE
  VALIDATE $? "Roboshop System user added"
else
  echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "/app directory is created"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "catalogue zip download"

cd /app &>> $LOGS_FILE
VALIDATE $? "moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip | tee -a $LOGS_FILE
VALIDATE $? "unzip catalogue"

npm install &>> $LOGS_FILE
VALIDATE $? "Install dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service | tee -a $LOGS_FILE
VALIDATE $? "copy catalogue service file"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "deamon reload"

systemctl enable catalogue | tee -a $LOGS_FILE
VALIDATE $? "Enable catalogue"

systemctl start catalogue | tee -a $LOGS_FILE
VALIDATE $? "Start catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo | tee -a $LOGS_FILE
VALIDATE $? "copy the mongo repo dirctory"

dnf install mongodb-mongosh -y | tee -a $LOGS_FILE
VALIDATE $? "install mongodb client"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
     mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
     echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue &>> $LOGS_FILE
VALIDATE $? "Restarting catalogue"