ARG BASE_IMAGE=alpine:3.19
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.authors="Chris Romp"
LABEL org.opencontainers.image.description="A containerized implementation of the Visual Studio Code Remote Tunnels server."
LABEL org.opencontainers.image.source = "https://github.com/ChrisRomp/vscodetunnel"

# Install packages
RUN apk update && \
    apk add --no-cache \
    bash buildah ca-certificates curl git gnupg jq less make nodejs npm openssl unzip vim wget zip sudo iproute2 bind-tools python3 py3-pip && \
    rm -rf /var/cache/apk/*

# Download and install VS Code CLI based on architecture
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        curl -sSLf 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-arm64' --output /tmp/vscode-cli.tar.gz; \
    else \
        curl -sSLf 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output /tmp/vscode-cli.tar.gz; \
    fi && \
    tar -xf /tmp/vscode-cli.tar.gz -C /usr/local/bin && \
    rm -f /tmp/vscode-cli.tar.gz

COPY vscode-tunnel.sh /vscode-tunnel.sh
RUN chmod +x /vscode-tunnel.sh

# Personal preferences
RUN echo 'alias ll="ls -alh --color=auto"' >> /etc/profile.d/aliases.sh
RUN mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh
ENV ENV="/etc/profile"

# Create user
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_NAME=vscode
RUN addgroup -g ${USER_GID} ${USER_NAME} && \
    adduser --uid ${USER_UID} --ingroup ${USER_NAME} --ingroup ${USER_NAME} \
    --shell /bin/bash --gecos "${USER_NAME}" --disabled-password ${USER_NAME}

# Enable sudo for user
RUN addgroup ${USER_NAME} wheel
RUN echo '%wheel ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/wheel

# Copy files from userhome to /home/${USER_NAME}
COPY --chown=${USER_UID}:${USER_GID} ./userhome/* /home/${USER_NAME}
RUN chmod 664 /home/${USER_NAME}/.bashrc

# Workspace config
ARG VSCODE_WORKSPACE_DIR=/home/${USER_NAME}/work
ENV VSCODE_WORKSPACE_DIR=${VSCODE_WORKSPACE_DIR}
RUN mkdir -p ${VSCODE_WORKSPACE_DIR} && chown ${USER_UID}:${USER_GID} ${VSCODE_WORKSPACE_DIR}
RUN chmod 775 ${VSCODE_WORKSPACE_DIR}
WORKDIR ${VSCODE_WORKSPACE_DIR}

# Annotate for workspace volume mount (optional)
VOLUME [ "${VSCODE_WORKSPACE_DIR}" ]

# Authentication provider for tunnel server: microsoft, github
ENV VSCODE_TUNNEL_AUTH=microsoft

# Optional "dev tunnel" token for authentication so you can skip tunnel auth
# https://learn.microsoft.com/en-us/azure/developer/dev-tunnels
# Get token with `devtunnel user login` && `devtunnel user show -v`
ENV VSCODE_TUNNEL_ACCESS_TOKEN=

# Optional name for the tunnel server (defaults to hostname)
ENV VSCODE_TUNNEL_NAME=

# Optional install extensions comma-separated list (no spaces)
ENV VSCODE_EXTENSIONS=

USER ${USER_UID}
CMD ["/vscode-tunnel.sh"]
