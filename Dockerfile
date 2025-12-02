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
    pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118 && \
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
    pip install 'opencv-python==4.6.0.66' && \
    pip install cython wheel setuptools && \
    pip install 'numpy<1.23.0'
    
RUN wget -q -O 23506214.zip "https://www.dropbox.com/scl/fo/37q4kv0avrqnio77j2m45/AHBCjGDSomz8lBDKgqZ0TSc?rlkey=x10kl3ybojetw8uk7obhaxld2&st=hzv5pkhe" && \
    wget -q -O 23506226.zip "https://www.dropbox.com/scl/fo/a9p0psdwbaxlepizn5ffa/ALwuW-HiEATMIeLBoRGs5oo?rlkey=yziwod48z7z5vnnuri20zw795&st=0f2pcjus" && \
    wget -q -O 23506236.zip "https://www.dropbox.com/scl/fo/9jmn80tt5ekvyanntwkqx/AOESBYdNhNWShO4tro4LHpE?rlkey=k87nezuq9pxd7krcjxw6fv497&st=249odffl" && \
    wget -q -O 23506237.zip "https://www.dropbox.com/scl/fo/1erm1nck37lt9tb3h534u/ACbQfpJ_8-hMpBiybasaaLY?rlkey=9wfqwppxxt1lqwq2l2i1x0hz8&st=v8br9gkz" && \
    wget -q -O 23506239.zip "https://www.dropbox.com/scl/fo/s22gjyqji8fjx6dmypo1i/AHbkOsJlfj3SKeFeefRocEY?rlkey=oy4urlutk08fanoj5hw1njffl&st=0785fgi5" && \
    wget -q -O 23511607.zip "https://www.dropbox.com/scl/fo/0v857ijnnorjf2hdxuuli/AIjVsvszotMZP995STqFc8k?rlkey=d144zybikke3j8ca7zskmq6ky&st=1mfxqwu1" && \
    wget -q -O 23511613.zip "https://www.dropbox.com/scl/fo/ve7lo1afyn5hxks24hh7z/AECyHI542aKZWh9d1dI3Kmo?rlkey=5lkogrq4bce4ef9jbvgp9uum5&st=u830hhvw" && \
    wget -q -O 23511614.zip "https://www.dropbox.com/scl/fo/johngi3a0ebhvm5b3qcvb/AJ3fER3ga6IK3s2EZa-C3i0?rlkey=gu5xi3czlu7ebsygpyhp0q5vj&st=emmks486" && \
    wget -q -O weight.zip   "https://www.dropbox.com/scl/fo/u8uapca0azuaf4dknxjjx/AOSO5RqGob6NFKvkjSmhlQQ?rlkey=ujd1rhehzlmpoz0yjylgdf8gs&st=2ldcfzgm"

RUN sudo apt-get update && sudo apt-get install -y unzip && sudo rm -rf /var/lib/apt/lists/*

RUN sudo mkdir -p /app/vid && \
    sudo unzip /app/23506214.zip -d /app/vid/dailylife_cj611_20210903_080000.23506214 || echo "23506214.zip failed" && \
    sudo unzip /app/23506226.zip -d /app/vid/dailylife_cj611_20210903_080000.23506226 || echo "23506226.zip failed" && \
    sudo unzip /app/23506236.zip -d /app/vid/dailylife_cj611_20210903_080000.23506236 || echo "23506236.zip failed" && \
    sudo unzip /app/23506237.zip -d /app/vid/dailylife_cj611_20210903_080000.23506237 || echo "23506237.zip failed" && \
    sudo unzip /app/23506239.zip -d /app/vid/dailylife_cj611_20210903_080000.23506239 || echo "23506239.zip failed" && \
    sudo unzip /app/23511607.zip -d /app/vid/dailylife_cj611_20210903_080000.23511607 || echo "23511607.zip failed" && \
    sudo unzip /app/23511613.zip -d /app/vid/dailylife_cj611_20210903_080000.23511613 || echo "23511613.zip failed" && \
    sudo unzip /app/23511614.zip -d /app/vid/dailylife_cj611_20210903_080000.23511614 || echo "23511614.zip failed" && \
    sudo unzip weight.zip -d weight || echo "weight failed"

    # repository and minor or local resources
    RUN echo "invalidate: $CACHEBUST" && \
    git clone https://github.com/c7h2y/marmo3Dpose.git -b test/docker
    
    WORKDIR /app/marmo3Dpose
    RUN pip install --no-build-isolation src/m_lib

# ※ proxy_url は Dockerfile 内で ARG/ENV 定義されていないので、
#   必要なら ARG proxy_url / ENV proxy_url を追加することをおすすめします
RUN sudo bash ./proxyset.sh $http_proxy || echo "proxyset.sh skipped (proxy_url not set)"

RUN cp -r /app/vid /app/marmo3Dpose || true && \
    cp -r /app/weight /app/marmo3Dpose || true

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

# RUN bash docker_run_test.sh
