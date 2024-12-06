# Use a compatible base image
FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

# Set working directory
WORKDIR /app

# Set version label
ARG BUILD_DATE
ARG VERSION
ARG JACKETT_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    PORT=9117

# Install dependencies and Jackett
RUN apt-get update && \
    apt-get install -y \
        jq \
        libicu70 \
        wget \
        curl && \
    echo "**** Installing Jackett ****" && \
    mkdir -p /app/Jackett && \
    if [ -z ${JACKETT_RELEASE+x} ]; then \
        JACKETT_RELEASE=$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" | jq -r .tag_name); \
    fi && \
    curl -o /tmp/jacket.tar.gz -L "https://github.com/Jackett/Jackett/releases/download/${JACKETT_RELEASE}/Jackett.Binaries.LinuxAMDx64.tar.gz" && \
    tar xf /tmp/jacket.tar.gz -C /app/Jackett --strip-components=1 && \
    echo "**** Cleanup ****" && \
    apt-get clean && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Copy configuration files if needed
COPY ./config /config

# Set the container to run as a non-root user using base image's default user
USER 911

# Expose the application port
EXPOSE 9117

# Start Jackett
CMD ["/app/Jackett/jackett", "--NoRestart", "--NoUpdates", "-p", "$PORT"]
