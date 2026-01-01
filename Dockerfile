ARG ROCM_VERSION=6.2
ARG UBUNTU_VERSION=22.04
ARG HSA_OVERRIDE_GFX_VERSION=10.3.0
ARG USER_ID=1000
ARG GROUP_ID=1000

FROM rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}-complete

# Redeclare args after FROM for use in RUN commands
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG HSA_OVERRIDE_GFX_VERSION=10.3.0

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/rocm/bin:${PATH}"
ENV HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION}
ENV LD_LIBRARY_PATH="/opt/rocm/lib:/opt/rocm/lib64:${LD_LIBRARY_PATH}"
ENV ROCM_PATH="/opt/rocm"
ENV HIP_PLATFORM="amd"

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    libgomp1 \
    libstdc++6 \
    libfuse2 \
    file \
    libglib2.0-0 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    libatspi2.0-0 \
    libdrm2 \
    libgbm1 \
    libasound2t64 \
    xvfb \
    x11vnc \
    supervisor \
    net-tools \
    fluxbox \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC for web-based VNC access
RUN mkdir -p /opt/novnc /opt/novnc/utils/websockify \
    && curl -L https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xz --strip-components=1 -C /opt/novnc \
    && curl -L https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar -xz --strip-components=1 -C /opt/novnc/utils/websockify \
    && ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Create non-root user (handle existing UID/GID)
RUN (groupadd -g ${GROUP_ID} lmstudio 2>/dev/null || groupmod -n lmstudio $(getent group ${GROUP_ID} | cut -d: -f1)) \
    && (useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash lmstudio 2>/dev/null || usermod -l lmstudio -d /home/lmstudio -m $(getent passwd ${USER_ID} | cut -d: -f1)) \
    && usermod -aG video lmstudio \
    && usermod -aG render lmstudio

# Download and install LM Studio
WORKDIR /opt

# Download LM Studio AppImage
RUN curl -L -o lm-studio.AppImage "https://lmstudio.ai/download/latest/linux/x64" \
    && chmod +x lm-studio.AppImage \
    && chown lmstudio:lmstudio lm-studio.AppImage

# Create directories with proper ownership
RUN mkdir -p /home/lmstudio/.cache/lm-studio \
    && mkdir -p /var/log/supervisor \
    && chown -R lmstudio:lmstudio /home/lmstudio \
    && chown -R lmstudio:lmstudio /var/log/supervisor \
    && chown -R lmstudio:lmstudio /opt

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose API port and noVNC port
EXPOSE 1234 6080

WORKDIR /home/lmstudio

# Set display for X server
ENV DISPLAY=:99
ENV HOME=/home/lmstudio

# Start supervisor (manages Xvfb, VNC, noVNC, and LM Studio)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
