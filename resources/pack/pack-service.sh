#!/bin/bash

# service打包脚本

pack_status=0

function update_status(){
    if [ $1 -ne 0 ];then
        pack_status=$1
    fi
}
jarName=$packName
echo "WORKSPACE: $WORKSPACE"
echo "branch: $branch"
echo "appName: $appName"
echo "jarName: $jarName"
target_absolute_jar="./target/$jarName"

echo "target_absolute_jar: $target_absolute_jar"

time=`date +%Y%m%d%H%M`

if [ "$jgitflowFlag" = "none" ];then
    if [ -f $WORKSPACE/artifact/*.jar ];then
        rm $WORKSPACE/artifact/*.jar
    fi
    
    rm $WORKSPACE/target/*-sources.jar
    cp $WORKSPACE/target/*.jar $target_absolute_jar
    update_status $?

    mkdir -p $WORKSPACE/artifact && cp $target_absolute_jar $WORKSPACE/artifact/$jarName
    update_status $?


fi


