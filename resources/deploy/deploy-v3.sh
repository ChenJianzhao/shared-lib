#!/bin/bash

tomcat=tomcat-$appName
export app=$appName
export war=$packName
export env_flag=test

function copy_FET(){
    if [ -d "/usr/local/apps/corp/ROOT/ydhv2" ];then
        rm -rf /usr/local/apps/corp/ROOT/ydhv2
    fi
    
    if [ -d "/usr/local/apps/corp/ROOT/app/v2" ];then
        rm -rf /usr/local/apps/corp/ROOT/app/v2
    fi

    rm -rf /usr/local/apps/ydh/ROOT/app/index.html
    rm -rf /usr/local/apps/ydh/ROOT/app/index.dev.html
    rm -rf /usr/local/apps/ydh/ROOT/app/favicon.ico
    rm -rf /usr/local/apps/ydh/ROOT/app/fonts
    rm -rf /usr/local/apps/ydh/ROOT/app/img
    rm -rf /usr/local/apps/ydh/ROOT/app/ydh
    
    if [ -d "/usr/local/apps/resource/ROOT/dist/ydhv2" ];then
        rm -rf /usr/local/apps/resource/ROOT/dist/ydhv2
    fi
    
    if [ -d "/usr/local/apps/resource/ROOT/app/ydh/v2" ];then
        rm -rf /usr/local/apps/resource/ROOT/app/ydh/v2
    fi

    cp -rf /usr/local/apps/ircloud-ydh-web/ydh/ROOT/ydhv2 /usr/local/apps/corp/ROOT/
    cp -rf /usr/local/apps/ircloud-ydh-web/resource/ROOT/dist/ydhv2 /usr/local/apps/resource/ROOT/dist/
    cp -rf /usr/local/apps/ircloud-ydh-h5/ydh/ROOT/app/* /usr/local/apps/corp/ROOT/app/
    cp -rf /usr/local/apps/ircloud-ydh-h5/resource/ROOT/app/ydh/v2 /usr/local/apps/resource/ROOT/app/ydh/
}

function get_modify_time(){
    if [[ "$app" == "ircloud-ydh-web" ]];then
        modify_time=`stat ircloud-ydh-web-resource.zip | grep Modify |awk '{print $2,$3}'`
    elif [[ "$app" == "ircloud-ydh-h5" ]];then
        modify_time=`stat ircloud-ydh-h5-resource.zip | grep Modify |awk '{print $2,$3}'`
    else
        modify_time=`stat $war | grep Modify |awk '{print $2,$3}'`
    fi
    return $modify_time
}

if [ ! -d /usr/local/apps/$app/ ];then
    mkdir -p /usr/local/apps/$app/
    mkdir -p /usr/local/apps/$app/ROOT/
fi

if [ ! -d /alidata/log/$tomcat/ ];then
    mkdir -p /alidata/log/$tomcat/
fi

if [ ! -f /alidata/log/$tomcat/catalina.out ];then
    touch /alidata/log/$tomcat/catalina.out
fi

if [[ "$app" == "corsres" ]];then
    rm -rf /usr/local/apps/$app/ROOT/
    cp $war /usr/local/apps/$app/ROOT.war
    cd /usr/local/apps/$app/
    unzip -qu ROOT.war -d ROOT
elif [[ "$app" == "resource" ]];then
    rm -rf /usr/local/apps/$app/ROOT/
    cp $war /usr/local/apps/$app/ROOT.war
    cd /usr/local/apps/$app/
    unzip -qu ROOT.war -d ROOT
    copy_FET
elif [[ "$app" == "ircloud-ydh-web" ]];then
    ydh_zip=$app-$branch-ydh.zip
    resource_zip=$app-$branch-resource.zip
    echo "ydh_zip: $ydh_zip"
    echo "resource_zip: $resource_zip"

    rm -rf /usr/local/apps/$app/ydh/ROOT/ydhv2
    mkdir -p /usr/local/apps/$app/ydh/ROOT/ydhv2
    cp $ydh_zip /usr/local/apps/$app/
    unzip -qu $ydh_zip -d /usr/local/apps/$app/ydh/

    rm -rf /usr/local/apps/$app/resource/ROOT/dist/ydhv2
    mkdir -p /usr/local/apps/$app/resource/ROOT/dist/ydhv2
    cp $resource_zip /usr/local/apps/$app/
    unzip -qu $resource_zip -d /usr/local/apps/$app/resource/
    copy_FET
elif [[ "$app" == "ircloud-ydh-h5" ]];then
    ydh_zip=$app-$branch-ydh.zip
    resource_zip=$app-$branch-resource.zip
    echo "ydh_zip: $ydh_zip"
    echo "resource_zip: $resource_zip"

    rm -rf /usr/local/apps/$app/ydh/ROOT/app
    mkdir -p /usr/local/apps/$app/ydh/ROOT/app
    cp $ydh_zip /usr/local/apps/$app/
    unzip -qu $ydh_zip -d /usr/local/apps/$app/ydh/

    rm -rf /usr/local/apps/$app/resource/ROOT/app/ydh/v2
    mkdir -p /usr/local/apps/$app/resource/ROOT/app/ydh/v2
    cp $resource_zip /usr/local/apps/$app/
    unzip -qu $resource_zip -d /usr/local/apps/$app/resource/
    copy_FET
else
    echo "web应用部署到tomcat脚本"
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
    copy_FET
fi

# 发送钉钉部署通知
if [ -z $branch ];then
    branch=develop
fi

if [ -z $build_user ];then
    build_user=none
fi

#if [ ! -z $env_flag ];then
#    # 部署通知
#    python deploy_notification.py $app $branch $env_flag $build_user
#    # 上传部署时间
#    python deploy_info.py $app $branch $build_user
#fi