ARG ROCM_VERSION=6.2
ARG UBUNTU_VERSION=22.04
ARG HSA_OVERRIDE_GFX_VERSION=10.3.0

FROM rocm/dev-ubuntu-${UBUNTU_VERSION}:${ROCM_VERSION}-complete

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

# Download and install LM Studio
WORKDIR /opt

# Download LM Studio AppImage
RUN curl -L -o lm-studio.AppImage "https://lmstudio.ai/download/latest/linux/x64" \
    && chmod +x lm-studio.AppImage

# Create models directory
RUN mkdir -p /root/.cache/lm-studio

# Create supervisor config
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose API port and noVNC port
EXPOSE 1234 6080

WORKDIR /root

# Set display for X server
ENV DISPLAY=:99

# Start supervisor (manages Xvfb, VNC, noVNC, and LM Studio)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
