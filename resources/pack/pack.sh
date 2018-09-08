#!/bin/bash

# web应用打包脚

pack_status=0

function update_status(){
    if [ $1 -ne 0 ];then
        pack_status=$1
    fi
}


warName=$packName
echo "WORKSPACE: $WORKSPACE"
echo "branch: $branch"

echo "appName: $appName"
echo "warName: $warName"


time=`date +%Y%m%d%H%M`

if [ "$jgitflowFlag" = "none" ];then
    if [ -f $WORKSPACE/artifact/*.war ];then
        rm $WORKSPACE/artifact/*.war
    fi

    #rm $WORKSPACE/target/*-sources.war
    update_status $?

    mkdir -p $WORKSPACE/artifact && cp $WORKSPACE/target/*.war $WORKSPACE/artifact/$warName
    update_status $?
fi

