if [ -z "$JAVA_OPTS" ];then
    JAVA_OPTS="-Xms128M -Xmx512M -Dfile.encoding=UTF8 -Duser.timezone=GMT+08 "
fi

if [ -z "$BOOTSTRAP_PROPERTIES" ];then
    BOOTSTRAP_PROPERTIES="--spring.profiles.active=dev --eureka.client.serviceUrl.defaultZone=http://192.168.1.249:11003/eureka/,http://192.168.1.249:11004/eureka/"
fi

if [ -z $tagOr ];then
    java $JAVA_OPTS -jar __jar_name__ $BOOTSTRAP_PROPERTIES
else
    java $JAVA_OPTS -jar __jar_name__ $BOOTSTRAP_PROPERTIES --eureka.instance.metadata-map.tagOr=$tagOr
fi
