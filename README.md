# LM Studio ROCm Stack

Run LM Studio in a container with AMD ROCm and GUI access via web-based VNC. The container runs an X server (Xvfb), VNC server (x11vnc), and noVNC for browser-based GUI access.

## Prerequisites
- Docker + docker compose (v2+)
- ROCm drivers on the host with `/dev/kfd` and `/dev/dri` available
- User in the `video` group (or run with a user that has access to the GPU devices)

### Verify ROCm Installation
```bash
# Check ROCm version
rocminfo | grep "HSA Runtime Version"

# List available GPUs
rocm-smi

# Check GPU architecture (gfx version)
rocminfo | grep "Name:" -A 5
```

## Configure
1) Copy or edit `.env`:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```
   - `ROCM_VERSION`: ROCm version for the base image (e.g., `6.2`).
   - `MODELS_DIR`: host path for model weights; will be mounted to `/root/.cache/lm-studio` in the container.
   - `GPU_IDS`: `all` or comma-separated GPU IDs for `HIP_VISIBLE_DEVICES`.
   - `PORT`: host port to bind to the LM Studio UI/API (container uses 1234).
2) Ensure the host models directory exists: `mkdir -p "$MODELS_DIR"`.

## Build & Run
- Build image (downloads LM Studio 0.3.36): `docker compose build`
- Start: `docker compose up -d`
- View logs: `docker compose logs -f`
- Stop: `docker compose down`
- Access GUI (via web browser): `http://localhost:6080` (or your configured `VNC_PORT`)
- Access API: `http://localhost:1234` (or your configured `PORT`)

## Enable ROCm GPU Support

**Important:** LM Studio does not include ROCm support by default. Follow these steps to enable AMD GPU acceleration:

1. **Start the container and access the GUI:**
   ```bash
   docker compose up -d
   ```
   Open your browser to `http://localhost:6080`

2. **Download the ROCm runtime:**
   - In LM Studio, click on the **Hardware** tab (or Mission Control → Hardware)
   - Under the GPUs section, you'll see "0 GPUs detected"
   - Click on **Runtime** or **Settings** 
   - Find and download the **ROCm llama.cpp runtime** backend
   - Wait for the download to complete

3. **Restart the container:**
   ```bash
   docker compose down
   docker compose up -d
   ```

4. **Verify GPU detection:**
   - Open the GUI again at `http://localhost:6080`
   - Go to Hardware settings
   - You should now see your AMD GPUs detected (e.g., "2 GPUs detected")

After these steps, you can download and run models with ROCm GPU acceleration.

## Rebuild image
- Rebuild with updated Dockerfile: `docker compose build --no-cache && docker compose up -d`

## Download & Install Models

### Option 1: Using the LM Studio CLI inside the container
```bash
# Access the container shell
docker exec -it lm-studio-rocm /bin/bash

# From inside the container, use LM Studio CLI
cd /opt
./lm-studio.AppImage --appimage-extract-and-run --no-sandbox --help
```

### Option 2: Manual download to the host
1) Download GGUF model files from Hugging Face (e.g., [TheBloke's quantized models](https://huggingface.co/TheBloke))
2) Place them in your `MODELS_DIR` (e.g., `/home/shaun/Data/lm-studio/models/`)
3) Models are automatically available to LM Studio in the container

### Option 3: Using the API
```bash
# List loaded models
curl http://localhost:1234/v1/models

# Load a model via API (check LM Studio docs for endpoint)
```

**Note**: The container must be running for CLI commands to work. Models persist in the mapped `MODELS_DIR` volume across restarts.

## Notes
- The compose file maps `/dev/kfd` and `/dev/dri`, sets `group_add: [video]`, `ipc: host`, and `shm_size: 8g` to reduce OOM in large models.
- The mapped models folder persists weights across container restarts.
- To target specific GPUs, set `GPU_IDS` to a list like `0,2`.

## Troubleshooting
- Permission denied on `/dev/kfd` or `/dev/dri`: add your user to `video` group and re-login, or run `docker compose` with a user that has access.
- No GPUs visible: confirm ROCm drivers are loaded on the host and `HIP_VISIBLE_DEVICES` matches available devices.
- Port already in use: change `PORT` or `VNC_PORT` in `.env` (e.g., `PORT=1235`, `VNC_PORT=6081`).
- Wrong GPU architecture detected: adjust `HSA_OVERRIDE_GFX_VERSION` in `.env` to match your GPU's gfx version (see `rocminfo | grep "Name:" -A 5`).
- VNC not accessible: ensure port 6080 is not blocked by firewall and container is running (`docker compose ps`).
- Black screen in VNC: check logs with `docker compose logs lm-studio` to see if LM Studio started successfully.

## Resources
- [LM Studio Documentation](https://lmstudio.ai/docs)
- [ROCm GPU Support Matrix](https://rocm.docs.amd.com/en/latest/release/gpu_os_support.html)
- [ROCm Installation Guide](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/)
- [Docker ROCm Images](https://hub.docker.com/r/rocm/dev-ubuntu-22.04/tags)
