# Version:0.1
FROM openjdk:8u131-jdk
MAINTAINER xuekj <xuekj@77ircloud.com>

# RUN echo "docker:x:6666::/alidata/apps/__app_name__:" >> /etc/passwd

# USER docker

ENV LANG C.UTF-8
COPY localtime /etc/localtime

WORKDIR /alidata/apps/__app_name__
ADD __jar_name__ /alidata/apps/__app_name__
ADD run.sh /alidata/apps/__app_name__
# RUN chown -R docker /alidata/apps/__app_name__

CMD ["sh", "run.sh"]
