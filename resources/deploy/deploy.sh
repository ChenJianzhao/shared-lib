#!/bin/bash
tomcat=tomcat-$appName
app=$appName
war=$packName

# web应用部署到tomcat脚本
if [ ! -d /usr/local/apps/$app/ ];then
    mkdir -p /usr/local/apps/$app/
    mkdir -p /usr/local/apps/$app/ROOT/
fi

if [ ! -d /alidata/log/$tomcat/ ];then
    mkdir -p /alidata/log/$tomcat/
fi

ps -ef | grep tomcat | grep $tomcat | grep -v tomcat-ydh-try | grep -v grep | grep -v continuum | awk '{ system("kill -9 " $2) }'
rm -rf /usr/local/$tomcat/work/*
rm -rf /usr/local/$tomcat/logs/*
rm -rf /usr/local/$tomcat/temp/*
rm -rf /usr/local/apps/$app/*.war
rm -rf /usr/local/apps/$app/ROOT/*

cp $war /usr/local/apps/$app/ROOT.war
cd /usr/local/apps/$app/
unzip -qu ROOT.war -d ROOT

/usr/local/$tomcat/bin/startup.sh

#if [ -z $branch ];then
#    branch=develop
#fi

#if [ ! -z $env_flag ];then
#    python deploy_notification.py $app $branch $env_flag
#fi

