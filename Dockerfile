# Use a compatible base image
FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic

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
    PORT=9117 \
    FLARESOLVERR_PORT=8191

# Install dependencies, Jackett, and FlareSolverr in a single RUN step to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    jq \
    libicu60 \
    libssl1.0 \
    wget \
    curl \
    ca-certificates \
    openjdk-11-jre-headless && \
    echo "**** install Jackett ****" && \
    JACKETT_RELEASE=${JACKETT_RELEASE:-$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" | jq -r .tag_name)} && \
    curl -o /tmp/jacket.tar.gz -L "https://github.com/Jackett/Jackett/releases/download/${JACKETT_RELEASE}/Jackett.Binaries.LinuxAMDx64.tar.gz" && \
    mkdir -p /app/Jackett && \
    tar xf /tmp/jacket.tar.gz -C /app/Jackett --strip-components=1 && \
    chown -R root:root /app/Jackett && \
    echo "**** install FlareSolverr ****" && \
    curl -o /tmp/flaresolverr.tar.gz -L "https://github.com/FlareSolverr/FlareSolverr/releases/latest/download/flaresolverr-linux-x64.tar.gz" && \
    mkdir -p /app/FlareSolverr && \
    tar xf /tmp/flaresolverr.tar.gz -C /app/FlareSolverr --strip-components=1 && \
    chmod +x /app/FlareSolverr/flaresolverr && \
    rm -rf /tmp/jacket.tar.gz /tmp/flaresolverr.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*

# Expose ports for Jackett and FlareSolverr
EXPOSE 9117 8191

# Copy configuration files if needed
COPY ./config /config

# Set up entrypoint script to run both Jackett and FlareSolverr
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
