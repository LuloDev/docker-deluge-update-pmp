FROM lscr.io/linuxserver/deluge:latest
LABEL maintainer="LuloDev"

## add scripts with permissions
ADD update_deluge_port.sh /scripts/update_deluge_port.sh
RUN chmod +x /scripts/update_deluge_port.sh


RUN \
    echo "**** install packages packages ****" && \
    apk update && \
    apk add --no-cache git grep

RUN echo "**** cloning py-natpmp ****" && \
    git clone https://github.com/yimingliu/py-natpmp /scripts/py-natpmp

RUN echo "**** config crontab ****" && \
    echo "* * * * * sleep 50 /bin/sh /scripts/update_deluge_port.sh" > /scripts/crontab && \
    crontab /scripts/crontab

RUN echo "**** cleanup ****" && \
    apk del git 


VOLUME /config
EXPOSE 8112 58846 58946 58946/udp