FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

WORKDIR /app

# Set version label
ARG BUILD_DATE
ARG VERSION
ARG JACKETT_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    PORT=9117

# Create a non-root user and group
RUN groupadd -g 1000 jackettgroup && \
    useradd -u 1000 -g jackettgroup -d /config -s /bin/bash jackettuser

RUN \
    echo "**** Install packages ****" && \
    apt-get update && \
    apt-get install -y \
        jq \
        libicu60 \
        libssl1.0 \
        wget && \
    echo "**** Install Jackett ****" && \
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
    echo "**** Fix for host ID mapping error ****" && \
    chown -R jackettuser:jackettgroup /app/Jackett && \
    echo "**** Save Docker image version ****" && \
    echo "${VERSION}" > /etc/docker-image && \
    echo "**** Cleanup ****" && \
    apt-get clean && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

# Copy configuration
COPY ./config /config

# Adjust permissions for the /config directory
RUN chown -R jackettuser:jackettgroup /config

# Switch to the non-root user
USER jackettuser

# Expose necessary port
EXPOSE 9117

# Start Jackett
CMD exec /app/Jackett/jackett --NoRestart --NoUpdates -p $PORT
