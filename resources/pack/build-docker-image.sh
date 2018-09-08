#!/bin/bash

# 构建微服务docker镜像

registry=192.168.1.249:5000
jarName=$packName
echo "WORKSPACE: $WORKSPACE"
echo "branch: $branch"
echo "baseDeployDir: $baseDeployDir"
echo "appName: $appName"
echo "jarName: $jarName"
branch=$(echo $branch | sed 's_/_-_g')

time=`date +%Y%m%d%H%M`

if [ "$jgitflowFlag" = "none" ];then
    
    cd $WORKSPACE   
    cp /etc/localtime $WORKSPACE
    sed -i "s/__jar_name__/$appName-$branch.jar/g" $WORKSPACE/Dockerfile
    sed -i "s/__jar_name__/$appName-$branch.jar/g" $WORKSPACE/run.sh
    sed -i "s/__app_name__/$appName/g" $WORKSPACE/Dockerfile


    docker build -t $registry/$appName:$branch-$buildNumber .

    docker push $registry/$appName:$branch-$buildNumber
fi

