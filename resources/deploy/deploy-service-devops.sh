#!/bin/bash

# 部署fatjar脚本
app=$appName
jar=$packName

target_pid=`ps -ef |grep "/alidata/apps/$app/" |grep -v grep |awk '{print $2}'`

if [ ! -z "$target_pid" ];then
    kill -9 $target_pid
fi

if [ ! -d /alidata/apps/$app ];then
    mkdir -p /alidata/apps/$app
fi
chown -R develop:develop /alidata/apps/$app

if [ ! -d /alidata/log/$app ];then
    mkdir -p /alidata/log/$app
fi
chown -R develop:develop /alidata/log
chown -R develop:develop /alidata/log/$app
chown -R develop:develop /alidata/apps/$app

rm -rf /alidata/apps/$app/*.jar

cp $jar /alidata/apps/$app/
cd /alidata/apps/$app/

parameters="--logging.file=/alidata/log/$app/$app.log"

if [ ! -z "$profiles_active" ];then
    parameters="$parameters --spring.profiles.active=$profiles_active"
else
    parameters="$parameters --spring.profiles.active=dev"
fi

is_develop_env=`/sbin/ifconfig  | grep '192.168.1.249' |wc -l`
if [ ! -z "$tagOr" ];then
    parameters="$parameters --eureka.instance.metadata-map.tagOr=$tagOr"
else
    if [ $is_develop_env -eq 1 ];then
        parameters="$parameters --eureka.instance.metadata-map.tagOr=develop"
    fi
fi

if [ ! -z "$custom_parameters" ];then
    parameters="$parameters $custom_parameters"
fi

if [ -z "$Xmx" ];then
    Xmx=512m
fi

echo "source /etc/profile" > /alidata/apps/$app/run.sh
echo "cd /alidata/apps/$app" >> /alidata/apps/$app/run.sh


DEFAULT_JAVA_OPTS="-XX:-OmitStackTraceInFastThrow -XX:+UseConcMarkSweepGC -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses -XX:+CMSClassUnloadingEnabled -XX:+ParallelRefProcEnabled -XX:+CMSScavengeBeforeRemark -XX:ErrorFile=/alidata/log/$app/hs_err_pid%p.log -XX:HeapDumpPath=/alidata/log/$app/ -XX:+HeapDumpOnOutOfMemoryError -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/alidata/log/$app/gc/gc_pid%p.log"

if [ -z "$ptest_flag" ];then
    echo "nohup java -Xms128m -Xmx$Xmx $DEFAULT_JAVA_OPTS -jar /alidata/apps/$app/$jar --hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds=10000 $parameters >> /alidata/log/$app/catalina.out 2>&1 &" >> /alidata/apps/$app/run.sh
else
    echo "nohup java -Xms$Xmx -Xmx$Xmx $DEFAULT_JAVA_OPTS -jar /alidata/apps/$app/$jar $parameters >> /alidata/log/$app/catalina.out 2>&1 &" >> /alidata/apps/$app/run.sh
fi

echo "echo \$! > /alidata/apps/$app/run.pid" >> /alidata/apps/$app/run.sh

chmod +x /alidata/apps/$app/run.sh
chown develop:develop /alidata/apps/$app/run.sh
chown develop:develop /alidata/apps/$app/$jar

## TODO 删除了旧的日志，下方要判断 Tomcat 是否已经启动，（是否可以删除后续待定）
rm -f "/alidata/log/$app/catalina.out"

su - develop -c /alidata/apps/$app/run.sh

if [ -z "$branch" ];then
    branch=develop
fi

if [ -z "$build_user" ];then
    build_user=none
fi

if [ ! -z "$env_flag" ];then
    python deploy_notification.py $app $branch $env_flag $build_user
fi

exptime=0
while true
do
      running_pid=$(cat /alidata/apps/$app/run.pid)
      echo $running_pid
      port=`netstat -tnpl | grep "$running_pid" | awk '{print $4}' | cut -d ':' -f 4`

      ret=`curl -s -I -o /dev/null -w '%{http_code}' http://localhost:$port/health`
      if [ "$ret" != "200" ]; then
          sleep 1
          ((exptime++))
          echo -n -e  "\rWait Tomcat Start: $exptime...\n"
      else
         echo 'has server startup'
         break
      fi
done