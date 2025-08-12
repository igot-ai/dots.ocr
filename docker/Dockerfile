# ==============================================================================
# Multi-stage Dockerfile combining:
# 1. rednotehilab/dots.ocr:vllm-openai-v0.9.1 (for pre-built vLLM and OCR components)
# 2. nvidia/cuda:12.6.0-devel-ubuntu22.04 (for CUDA development environment)
# ==============================================================================

# Stage 1: Source image with pre-built dots.ocr and vLLM components
FROM rednotehilab/dots.ocr:vllm-openai-v0.9.1 AS dots_ocr_source

# Stage 2: Main build based on NVIDIA CUDA for GPU support
FROM nvidia/cuda:12.6.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install system dependencies and Python 3.12
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    wget \
    curl \
    build-essential \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    git \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgcc-s1 \
    sudo \
    vim \
    nano \
    poppler-utils \
    tesseract-ocr \
    libtesseract-dev \
    libleptonica-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install NVIDIA utilities (nvidia-smi) matching host driver version 575.x
RUN apt-get update && apt-get install -y \
    nvidia-utils-575 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/local/cuda/lib64/libcudart.so.12 /usr/local/cuda/lib64/libcudart.so

# Set python3.12 as default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# Install additional Python packages and pip for Python 3.12
RUN apt-get update && apt-get install -y python3.12-distutils || true \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user and add to sudo group
RUN useradd --create-home --shell /bin/bash app && \
    usermod -aG sudo app && \
    echo "app ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers && \
    chown -R app:app /home/app

# Set working directory
WORKDIR /app

# Copy requirements files for better Docker layer caching
COPY requirements*.txt ./

# Install Python dependencies in correct order
RUN python3.12 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy Python packages from dots.ocr source image if available
COPY --from=dots_ocr_source /usr/local/lib/python*/site-packages/ /usr/local/lib/python3.12/site-packages/ || true


# Install remaining application dependencies (vllm==0.9.1 should match source image)
RUN python3.12 -m pip install --no-cache-dir -r requirements.txt

# Copy pre-built components from dots.ocr source image (if any exist)
COPY --from=dots_ocr_source /app/ /app/dots_ocr_base/ || true

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
