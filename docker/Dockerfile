# ==============================================================================
# Dockerfile based on nvidia/cuda:12.6.0-devel-ubuntu22.04 
# for proper CUDA support and GPU detection in vLLM
# ==============================================================================

FROM nvidia/cuda:12.6.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64/stubs
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV PATH=/usr/local/cuda/bin:${PATH}

# vLLM platform detection environment variables
ENV VLLM_USE_TRITON=1
ENV VLLM_TARGET_DEVICE=cuda
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn
ENV CUDA_VISIBLE_DEVICES=0
ENV CUDA_DEVICE_ORDER=PCI_BUS_ID

# Note: We'll install packages fresh instead of copying from source image
# This ensures compatibility with the new CUDA base image

# Install system dependencies and CUDA runtime
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    wget \
    curl \
    build-essential \
    git \
    vim \
    nano \
    sudo \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    poppler-utils \
    tesseract-ocr \
    libtesseract-dev \
    libleptonica-dev \
    pkg-config \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    nvidia-utils-545 \
    libnvidia-compute-545 \
    && rm -rf /var/lib/apt/lists/*

# Create python symlink and verify installations
RUN if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi && \
    python3 --version && \
    python3 -m pip --version

# Verify CUDA installation and create necessary symlinks
RUN ldconfig && \
    ln -sf /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && \
    echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/cuda-stubs.conf && \
    ldconfig

# Create app user if it doesn't exist, or update existing user
RUN id -u app >/dev/null 2>&1 || useradd --create-home --shell /bin/bash app && \
    usermod -aG sudo app && \
    echo "app ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers && \
    chown -R app:app /home/app

# Set working directory
WORKDIR /app

# Copy requirements files for better Docker layer caching
COPY requirements*.txt ./

# Update pip and install additional dependencies
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel


# Install vLLM with CUDA support
RUN python3 -m pip install --no-cache-dir vllm==0.9.1 transformers==4.51.3

# Install additional application dependencies from requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copy application code (this will override any existing files)
COPY . .

# Create necessary directories as root with proper structure
RUN chown -R app:app /app && \
    chmod -R 755 /app

# Verify CUDA and GPU detection
RUN echo "Verifying CUDA installation..." && \
    nvcc --version && \
    nvidia-smi || echo "nvidia-smi not available (expected in build, will work at runtime)" && \
    python3 -c "import torch; print(f'PyTorch CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda if torch.cuda.is_available() else \"Not available\"}')" || echo "PyTorch verification will be done after pip install"

# Create a script for package installation (if needed)
RUN echo '#!/bin/bash\n\
if [ "$EUID" -eq 0 ]; then\n\
    apt-get update && apt-get install -y "$@"\n\
else\n\
    echo "Run as root: docker exec --user root <container> install-packages <package-names>"\n\
fi' > /usr/local/bin/install-packages && \
    chmod +x /usr/local/bin/install-packages

# Switch to non-root user
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000
