# ==============================================================================
# Dockerfile based on rednotehilab/dots.ocr:vllm-openai-v0.9.1
# with additional CUDA development tools from nvidia/cuda:12.6.0-devel-ubuntu22.04
# ==============================================================================

FROM rednotehilab/dots.ocr:vllm-openai-v0.9.1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# vLLM platform detection environment variables
ENV VLLM_USE_TRITON=1
ENV VLLM_TARGET_DEVICE=cuda
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn
ENV CUDA_VISIBLE_DEVICES=0

# Install additional CUDA development tools and system dependencies
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
    && rm -rf /var/lib/apt/lists/*

# Create python symlink if it doesn't exist and verify Python installation
RUN if [ ! -f /usr/bin/python ]; then ln -s /usr/bin/python3 /usr/bin/python; fi && \
    python3 --version && \
    python3 -m pip --version

# Ensure CUDA development tools are available (if not already present)
RUN apt-get update && apt-get install -y \
    cuda-toolkit-12-6 || true \
    && rm -rf /var/lib/apt/lists/*

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
RUN python3.12 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Install base dependencies first if requirements-base.txt exists
RUN if [ -f requirements-base.txt ]; then \
        python3 -m pip install --no-cache-dir -r requirements-base.txt; \
    fi

# Install additional application dependencies from requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create necessary directories as root with proper structure
RUN chown -R app:app /app && \
    chmod -R 755 /app

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
