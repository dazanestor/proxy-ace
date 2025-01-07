# syntax=docker/dockerfile:1

FROM ubuntu:22.04

# Mantainer Information
LABEL maintainer="Unified Dockerfile" \
      org.opencontainers.image.authors="Unified Integration"

# Environment Variables
ENV ACESTREAM_VERSION="3.2.3_ubuntu_22.04_x86_64_py3.10" \
    OVPN_FILES="https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip" \
    OVPN_CONFIG_DIR="/app/ovpn/config" \
    SERVER_RECOMMENDATIONS_URL="https://api.nordvpn.com/v1/servers/recommendations" \
    SERVER_STATS_URL="https://nordvpn.com/api/server/stats/" \
    CRON="*/15 * * * *" \
    CRON_OVPN_FILES="@daily" \
    PROTOCOL="tcp" \
    USERNAME="" \
    PASSWORD="" \
    COUNTRY="" \
    LOAD=75 \
    RANDOM_TOP="" \
    LOCAL_NETWORK="" \
    REFRESH_TIME="120" \
    ALLOW_REMOTE_ACCESS="no" \
    HTTP_PORT=6878 \
    EXTRA_FLAGS=''

# Set shell for pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install dependencies
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
      python3.10 \
      ca-certificates \
      wget \
      sudo \
      privoxy \
      openvpn \
      jq \
      curl \
      unzip \
      bash \
      ncurses-bin \
  && rm -rf /var/lib/apt/lists/*

# Configure AceStream
RUN wget --progress=dot:giga "https://download.acestream.media/linux/acestream_${ACESTREAM_VERSION}.tar.gz" \
  && mkdir acestream \
  && tar zxf "acestream_${ACESTREAM_VERSION}.tar.gz" -C acestream \
  && rm "acestream_${ACESTREAM_VERSION}.tar.gz" \
  && mv acestream /opt/acestream \
  && pushd /opt/acestream || exit \
  && bash ./install_dependencies.sh \
  && popd || exit

# Copy scripts and set permissions
COPY app /app
COPY run.sh /
RUN chmod +x /run.sh \
    && find /app -name run | xargs chmod u+x \
    && find /app -name *.sh | xargs chmod u+x

# Expose ports
EXPOSE 6878/tcp
EXPOSE 8118/tcp

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s \
  CMD if [[ $( curl -x localhost:8118 https://api.nordvpn.com/vpn/check/full | jq -r '."status"' ) = "Protected" ]] ; then exit 0; else exit 1; fi

# Entrypoint and default command
ENTRYPOINT ["/usr/bin/bash"]
CMD ["/run.sh"]
CMD ["runsvdir", "/app"]
