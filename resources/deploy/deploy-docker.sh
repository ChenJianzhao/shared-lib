#!/bin/bash

echo "WORKSPACE: $WORKSPACE"



service=$appName
branch=$(echo $branch | sed 's_/_-_g')

# 设置网络名
if [ -z "$network_name" ];then
    network_name=test
fi

# 设置docker私仓
if [ -z "$docker_registry" ];then
    docker_registry=192.168.1.249:5000
fi

# 设置挂载数据卷
volumn_conf="-v /etc/hosts:/etc/hosts"
log_dir_volumn=/alidata/log/
if [ ! -d "$log_dir_volumn" ];then
    mkdir -p $log_dir_volumn
fi
volumn_conf="$volumn_conf -v $log_dir_volumn:/alidata/log"



# 设置docker运行时环境变量集合
docker_env_properties="--env LANG=C.UTF-8 "

#优先取外部传进来的tagOr，没有则去接口查询（没有匹配配置会根据分支名获取默认配置）
if [ ! -z "$tagOr" ];then
    docker_env_properties="$docker_env_properties --env tagOr=$tagOr"
else
    tagOr=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=tagOr\&version=$version`
    if [ ! -z "$tagOr" ];then
        docker_env_properties="$docker_env_properties --env tagOr=$tagOr"
    fi
fi

DEFAULT_JAVA_OPTS="-XX:-OmitStackTraceInFastThrow -XX:+UseConcMarkSweepGC -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+CMSClassUnloadingEnabled -XX:+ParallelRefProcEnabled -XX:+CMSScavengeBeforeRemark -XX:ErrorFile=/alidata/log/$service/hs_err_pid%p.log -XX:HeapDumpPath=/alidata/log/$service/ -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/alidata/log/$service/gc/gc_pid%p.log"
if [ ! -z "$javaOps" ];then
    docker_env_properties="$docker_env_properties --env JAVA_OPTS=\"$javaOps $DEFAULT_JAVA_OPTS\""
fi

if [ ! -z "$bootstrapProperties" ];then

    #优先取外部传进来的server_port，没有则去接口查询（没有匹配配置会根据分支名获取默认配置）
    if [ ! -z "$serverPort" ];then
        bootstrapProperties="--server.port=$serverPort $bootstrapProperties"
    else
        server_port=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=server_port\&version=$version`
        if [ ! -z "$serverPort" ];then
            bootstrapProperties="--server.port=$serverPort $bootstrapProperties"
        fi
    fi

    # 获取profiles
    profiles=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=profiles\&version=$version`
    if [ ! -z "$profiles" ];then
        bootstrapProperties="$bootstrapProperties --spring.profiles.active=$profiles"
    fi

    # 获取ircloud-config
    ircloud_config=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=ircloud_config\&version=$version`
    if [ ! -z "$ircloud_config" ];then
        bootstrapProperties="$bootstrapProperties --ircloud.config.path=http://192.168.1.200:9527/$ircloud_config"
    fi


    # file-service不需要配置超时时间
    if [[ "$service" != "file-service" ]];then
            bootstrapProperties=" $bootstrapProperties --hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds=10000"
    fi

     # data-job 不会消费广播消息，需要添加特殊配置
    if [[ "$service" != "data-job" ]];then
            bootstrapProperties=" $bootstrapProperties --broadcast.consume.disable=false"
    elif [[ "$service" ==  "data-job" ]];then
            bootstrapProperties=" $bootstrapProperties --broadcast.consume.disable=true"
    fi


    # 网关需要特殊配置tags
    if [[ "$service" == "api-gateway" ]];then
        if [ ! -z "$tagOr" ];then
            bootstrapProperties=" $bootstrapProperties --zuul.header.tags=$tagOr"
        fi
    fi

    # 报表微服务抽离单独网关特殊配置
    if [[ "$service" == "report-api-gateway" ]];then
        if [ ! -z "$tagOr" ];then
            bootstrapProperties=" $bootstrapProperties --zuul.header.tags=$tagOr --spring.application.name=report-api-gateway"
        fi
    fi

    if [[ "$service" == "report-shunt-gateway" ]];then
        if [ ! -z "$tagOr" ];then
            bootstrapProperties=" $bootstrapProperties  --spring.application.name=report-shunt-gateway"
        fi
    fi

    #去接口查询路由标签（没有匹配配置会根据分支名获取默认配置）
    routeTags=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=routeTags\&version=$version`
    if [ ! -z "$routeTags" ];then
        bootstrapProperties="$bootstrapProperties --feign.request.header.routeTags=$routeTags "
    fi

    if [[ "$version" == "v1" ]];then
        docker_env_properties="$docker_env_properties --env bootstrapProperties=\"--logging.file=/alidata/log/$service/$service-$branch.log $bootstrapProperties\""
    else
        docker_env_properties="$docker_env_properties --env bootstrapProperties=\"--logging.file=/alidata/log/$service/$service-$branch-$version.log $bootstrapProperties\""
    fi
fi

echo "docker env: $docker_env_properties"

if [[ "$version" == "v1" ]];then
    container_name=$service-$branch-$containerTag
else
    container_name=$service-$branch-$version
fi

if [ ! -z $roll_back_version ];then
    image_name=$docker_registry/$service:$branch-$roll_back_version
else
    image_name=$docker_registry/$service:$branch-$buildNumber
fi

function stop_container()
{
    echo "stop container: $1"
    docker stop $1
}

function remove_container(){
    echo "remove container: $1"
    docker rm $1
}

function remove_image(){
    echo "remove image: $1"
    docker rmi $1
}

function pull_image(){
    echo "pull image $1"
    docker pull $1
}

function refresh_image(){
    branch=$1
    service=$2
    stop_container $container_name
    stop_container $container_name
    remove_container $container_name
    remove_image $image_name
    pull_image $image_name
    sleep 6
}

function service_discovery_center(){
    echo "call service_discovery_center"
    branch=$1
    service=service-discovery-center
    stop_container $container_name"1"
    stop_container $container_name"2"
    remove_container $container_name"1"
    remove_container $container_name"2"
    remove_image $image_name
    pull_image $image_name

    echo "run container: $service"

    bootstrap_properties=--spring.profiles.active=$containerTag"1"
    docker run -d $volumn_conf $customDockerConf --name $service-$branch-$containerTag"1" --env bootstrapProperties="$bootstrap_properties --eureka.server.enable-self-preservation=false" --restart=always --network=host $docker_registry/$service:$branch-latest

    bootstrap_properties=--spring.profiles.active=$containerTag"2"
    docker run -d $volumn_conf $customDockerConf --name $service-$branch-$containerTag"2" --env bootstrapProperties="$bootstrap_properties --eureka.server.enable-self-preservation=false" --restart=always --network=host $docker_registry/$service:$branch-latest
     
}

function run_service(){
    echo "call run_service"
    branch=$1
    service=$2
     
    refresh_image $branch $service

    echo "run container: $service"
    echo "docker run -d $volumn_conf $docker_env_properties $customDockerConf --name $container_name --restart=always --network=host $image_name" > run_docker.sh
    chmod +x run_docker.sh
    ./run_docker.sh
}

function check_network(){
    network=` docker network ls |grep $network_name |wc -l`
    if [ $network -eq 0 ];then
        docker network create $network_name
    fi
}

function check_service_up() {

    #优先取外部传进来的server_port，没有则去接口查询（没有匹配配置会根据分支名获取默认配置）
    if [ -z "$serverPort" ];then
        server_port=`curl -s  http://192.168.1.181:5000/ci/service/deploy/config/v2/?service=$service\&branch=$branch\&type=server_port\&version=$version`
    fi
    echo server_port: $serverPort

    exptime=0
    while true
    do
          ret=`curl -s -I -o /dev/null -w '%{http_code}' http://localhost:$serverPort/health`
          if [ "$ret" != "200" ]; then
              sleep 1
              ((exptime++))
              echo -n -e  "\rWait Tomcat Start: $exptime...\n"
          else
             echo 'has server startup'
             break
          fi
    done
}

#check_network

echo "target images:"
echo "    $image_name"

if [[ "$service" == "service-discovery-center" ]];then
    service_discovery_center $branch
else
    run_service $branch $service
    echo $serverPort
#    check_service_up
fi


if [ -z $branch ];then
    branch=develop
fi

if [ -z $build_user ];then
    build_user=none
fi

#if [ ! -z $env_flag ];then
#    python deploy_notification.py $service $branch docker $build_user
#    # 上传部署时间
#    python deploy_info.py $service $branch $build_user
#fi
