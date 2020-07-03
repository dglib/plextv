FROM ubuntu:16.04

ENV DEBIAN_FRONTEND="noninteractive" \
TERM="xterm" \
PLEX_MEDIA_SERVER_USER="abc" \
PLEX_MEDIA_SERVER_HOME="/usr/lib/plexmediaserver" \
PLEX_MEDIA_SERVER_INFO_DEVICE=docker \
PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS="6" \
PLEX_INSTALL="https://downloads.plex.tv/plex-media-server-new/1.19.4.2935-79e214ead/debian/plexmediaserver_1.19.4.2935-79e214ead_amd64.deb" \
HOME="/config"

ADD ["https://github.com/just-containers/s6-overlay/releases/download/v2.0.0.1/s6-overlay-amd64.tar.gz", \
     "/tmp/"]

# PREP IMAGE
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
    && apt-get update \
    && apt-get install -y curl sudo wget xmlstarlet uuid-runtime \
    && useradd -d /apps -s /bin/false abc \
    && useradd -U -d /config -s /bin/false -u 10001 plex \
    && usermod -G users plex \
    && mkdir -p /config /transcode /media

# INSTALL PLEX
RUN curl -o /tmp/plexmediaserver.deb -L "${PLEX_INSTALL}" \
    && dpkg -i /tmp/plexmediaserver.deb \
    && usermod -d /app abc

# CLEAN UP
RUN apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf var/tmp/*

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode /media

ENV VERSION=latest \
    CHANGE_DIR_RIGHTS="false" \
    CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

COPY root/ /
ENTRYPOINT ["/init"]
