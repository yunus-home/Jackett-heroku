# Use a compatible base image
FROM ubuntu:20.04

# Set working directory
WORKDIR /app

# Set version label
ARG BUILD_DATE
ARG VERSION
ARG JACKETT_RELEASE
LABEL build_version="Render-compatible version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="thelamer"

# Environment variables
ENV DEBIAN_FRONTEND="noninteractive" \
    XDG_DATA_HOME="/config" \
    XDG_CONFIG_HOME="/config" \
    PORT=9117

# Install dependencies and Jackett
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        jq \
        libicu66 \
        wget \
        curl \
        ca-certificates && \
    update-ca-certificates && \
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

# Add a non-root user for security
RUN useradd -u 10001 -m -d /config jackettuser && \
    chown -R jackettuser:jackettuser /app /config

# Switch to the non-root user
USER jackettuser

# Expose the application port
EXPOSE 9117

# Start Jackett
CMD ["/app/Jackett/jackett", "--NoRestart", "--NoUpdates", "-p", "$PORT"]
