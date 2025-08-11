# Use NVIDIA CUDA base image for GPU support (compatible with host CUDA 12.9)
FROM nvidia/cuda:12.6.0-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install system dependencies and Python 3.11.4
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-distutils \
    python3.11-venv \
    git \
    wget \
    curl \
    build-essential \
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

# Set python3.11 as default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Install pip for Python 3.11
RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python3.11 get-pip.py \
    && rm get-pip.py

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
RUN python3.11 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Install base dependencies first (PyTorch, etc.)
RUN python3.11 -m pip install --no-cache-dir -r requirements-base.txt

# Install flash-attn separately (requires torch to be available during build)
RUN python3.11 -m pip install --no-cache-dir -r requirements-flash.txt

# Install remaining application dependencies
RUN python3.11 -m pip install --no-cache-dir -r requirements-app.txt

# Copy application code first
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
