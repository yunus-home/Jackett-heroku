FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

WORKDIR /app

# set version label
ARG BUILD_DATE
ARG VERSION
ARG JACKETT_RELEASE
ARG FLARESOLVERR_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    PORT=9117 \
    FLARESOLVERR_PORT=8191

# Install dependencies, Jackett, and FlareSolverr
RUN \
 echo "**** install packages ****" && \
 apt-get update && \
 apt-get install -y \
    jq \
    libicu60 \
    libssl1.0 \
    wget \
    curl \
    openjdk-8-jre && \
 echo "**** install jackett ****" && \
 mkdir -p \
    /app/Jackett && \
 if [ -z ${JACKETT_RELEASE+x} ]; then \
    JACKETT_RELEASE=$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" \
    | jq -r .tag_name); \
 fi && \
 curl -o \
 /tmp/jacket.tar.gz -L \
    "https://github.com/Jackett/Jackett/releases/download/${JACKETT_RELEASE}/Jackett.Binaries.LinuxAMDx64.tar.gz" && \
 tar xf \
 /tmp/jacket.tar.gz -C \
    /app/Jackett --strip-components=1 && \
 echo "**** install flaresolverr ****" && \
 mkdir -p \
    /app/FlareSolverr && \
 if [ -z ${FLARESOLVERR_RELEASE+x} ]; then \
    FLARESOLVERR_RELEASE=$(curl -sX GET "https://api.github.com/repos/FlareSolverr/FlareSolverr/releases/latest" \
    | jq -r .tag_name); \
 fi && \
 curl -o \
 /tmp/flaresolverr.tar.gz -L \
    "https://github.com/FlareSolverr/FlareSolverr/releases/download/${FLARESOLVERR_RELEASE}/flaresolverr-linux-x64-${FLARESOLVERR_RELEASE}.tar.gz" && \
 tar xf \
 /tmp/flaresolverr.tar.gz -C \
    /app/FlareSolverr --strip-components=1 && \
 chmod +x /app/FlareSolverr/FlareSolverr && \
 echo "**** fix for host id mapping error ****" && \
 chown -R root:root /app/Jackett /app/FlareSolverr && \
 echo "**** save docker image version ****" && \
 echo "${VERSION}" > /etc/docker-image && \
 echo "**** cleanup ****" && \
 apt-get clean && \
 rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Copy configuration files if needed
COPY ./config /config

# Expose application ports
EXPOSE 9117 8191

# Run both Jackett and FlareSolverr
CMD ["/bin/bash", "-c", "exec /app/Jackett/jackett --NoRestart --NoUpdates -p $PORT & /app/FlareSolverr/FlareSolverr"]
