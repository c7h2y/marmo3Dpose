# syntax=docker/dockerfile:experimental

ARG http_proxy
ARG https_proxy

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 以降の RUN は bash -lc で動く
SHELL ["/bin/bash", "-lc"]

ARG http_proxy
ARG https_proxy
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV HTTP_PROXY=${http_proxy}
ENV HTTPS_PROXY=${https_proxy}

# 1) Create a non-root user and make /app owned by them
ARG USERNAME=pyuser
ARG GROUPNAME=pyuser
ARG UID=1000
ARG GID=1000
ARG WORKDIR=/app

RUN groupadd  -g $GID $GROUPNAME && \
    useradd   -m -s /bin/bash -u $UID -g $GID $USERNAME && \
    mkdir -p $WORKDIR && \
    chown -R $UID:$GID $WORKDIR

# 2) Install system packages + Python 3.10 + venv + pip
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo wget git unzip libgl1-mesa-glx libglib2.0-0 \
      software-properties-common \
      build-essential \
      python3.10 python3.10-venv python3.10-dev python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.10
RUN wget -qO /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python3.10 /tmp/get-pip.py && \
    rm /tmp/get-pip.py

# (2) sudoers.d ディレクトリを作成
RUN mkdir -p /etc/sudoers.d

# 3) sudoers.d にパスワード不要設定を追加
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# 3') venv を作成（グローバルに使う）
ENV VIRTUAL_ENV=/opt/venv
RUN python3.10 -m venv $VIRTUAL_ENV && \
    chown -R $UID:$GID $VIRTUAL_ENV

# venv を PATH に通す
ENV PATH=${VIRTUAL_ENV}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 4) Switch into your non-root user and /app
USER $USERNAME
WORKDIR $WORKDIR
ENV PYTHONPATH=$WORKDIR

# --------- ここ以降は venv の pip を使用 ---------

RUN pip install --upgrade pip && \
    pip install torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113 && \
    pip install wheel==0.38.4 && \
    pip install chumpy==0.70 --no-build-isolation && \
    # Open mmlab
    pip install openmim==0.3.9 && \
    mim install "mmcv-full==1.6.2" -f https://download.openmmlab.com/mmcv/dist/cu115/torch1.11/index.html && \
    mim install mmpose==0.29.0 && \
    mim install mmdet==2.26.0 && \
    mim install mmtrack==0.14.0 && \
    mim install mmcls==0.25.0 && \
    pip install xtcocotools==1.12 && \
    # Major tools
    pip install opencv-contrib-python==4.8.1.78 && \
    pip install numba==0.58.0 && \
    pip install h5py==3.9.0 && \
    pip install pyyaml==6.0.1 && \
    pip install toml==0.10.2 && \
    pip install matplotlib==3.8.0 && \
    pip install joblib==1.3.2 && \
    pip install imgstore==0.2.9 && \
    pip install 'opencv-contrib-python==4.6.0.66' && \
    pip install cython wheel setuptools && \
    pip install 'numpy<1.23.0'

    # repository and minor or local resources
RUN echo "invalidate: $CACHEBUST" && \
    git clone https://github.com/c7h2y/marmo3Dpose.git -b test/docker && \
    git clone https://github.com/open-mmlab/mmpose.git -b v0.29.0 && \
    git clone https://github.com/open-mmlab/mmdetection.git -b v2.26.0
RUN mkdir /app/work
WORKDIR /app/marmo3Dpose
RUN pip install --no-build-isolation src/m_lib

RUN sudo bash ./proxyset.sh $http_proxy || echo "proxyset.sh skipped (proxy_url not set)"

RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
      libgl1-mesa-glx \
      libglib2.0-0 && \
    sudo rm -rf /var/lib/apt/lists/*

RUN pip install 'scipy<1.23.0'
# CUDA のインストール先（シンボリックリンク）
ENV CUDA_HOME=/usr/local/cuda

# nvcc などのバイナリとライブラリを PATH／LD_LIBRARY_PATH に追加
ENV PATH=${CUDA_HOME}/bin:${PATH} \
    LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
RUN mkdir -p weight
RUN mkdir -p work
RUN mkdir -p vid

# RUN bash docker_run_test.sh
