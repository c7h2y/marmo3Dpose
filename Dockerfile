# syntax=docker/dockerfile:experimental


ARG proxy_url='http://ufproxy.b.cii.u-fukui.ac.jp:8080'

FROM nvidia/cuda:11.5.2-cudnn8-devel-ubuntu20.04

# これ以降の RUN は bash -lc で動き、conda init／activate が有効になる
SHELL ["/bin/bash", "-lc"]

ENV http_proxy  $proxy_url
ENV https_proxy $proxy_url

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

# 2) Make sure sudo/wget/git are still available
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo wget git unzip libgl1-mesa-glx libglib2.0-0 && \
    rm -rf /var/lib/apt/lists/*

# (2) sudoers.d ディレクトリを作成
RUN mkdir -p /etc/sudoers.d

    # 3) sudoers.d にパスワード不要設定を追加
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" \
     > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

    # 3) Install Miniconda & create your Python 3.10 env
RUN wget -qO ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash ~/miniconda.sh -b -p /opt/miniconda3 && \
    rm ~/miniconda.sh

ENV PATH=/opt/miniconda3/bin:$PATH

SHELL ["/bin/bash","-lc"]
RUN conda update -n base -c defaults conda -y && \
    conda create -n temp python=3.10.12 -y && \
    echo "conda activate temp" >> ~/.bashrc
    
# 4) Switch into your non-root user and /app
USER $USERNAME
WORKDIR $WORKDIR
ENV PYTHONPATH=$WORKDIR

ENV PATH=/opt/miniconda3/envs/temp/bin:/opt/miniconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/pyuser/.local/bin

RUN pip install torch==1.11.0+cu113 torchvision==0.12.0+cu113 torchaudio==0.11.0 --extra-index-url https://download.pytorch.org/whl/cu113 && \
    # Open mmlab
    pip install openmim==0.3.9 && \
    pip install mmcv-full==1.6.2 -f https://download.openmmlab.com/mmcv/dist/cu115/torch1.11.0/index.html && \
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
    pip install joblib==1.3.2

    
    # repository and minor or local resources echo "invalidate: $CACHEBUST" && 
    RUN echo "invalidate: $CACHEBUST" && git clone https://github.com/c7h2y/marmo3Dpose.git
    RUN pip install imgstore==0.2.9
    WORKDIR /app/marmo3Dpose
    RUN pip install 'src/m_lib'
    
    # Install MMPose
    # RUN conda clean --all
    
    RUN git checkout docker
    RUN sudo bash ./proxyset.sh $proxy_url
    RUN cp -r /app/vid /app/marmo3Dpose &&\
    cp -r /app/weight /app/marmo3Dpose
    RUN sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 && \
    sudo rm -rf /var/lib/apt/lists/*
    RUN pip install opencv-python
    
    # CUDA のインストール先（シンボリックリンク）
    ENV CUDA_HOME=/usr/local/cuda
    
    # nvcc などのバイナリとライブラリを PATH／LD_LIBRARY_PATH に追加
    ENV PATH=${CUDA_HOME}/bin:${PATH} \
    LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
    
    RUN wget -q -O 23506214.zip "https://www.dropbox.com/scl/fo/37q4kv0avrqnio77j2m45/AHBCjGDSomz8lBDKgqZ0TSc?rlkey=x10kl3ybojetw8uk7obhaxld2&st=hzv5pkhe" &&\
        wget -q -O 23506226.zip "https://www.dropbox.com/scl/fo/a9p0psdwbaxlepizn5ffa/ALwuW-HiEATMIeLBoRGs5oo?rlkey=yziwod48z7z5vnnuri20zw795&st=0f2pcjus" &&\
        wget -q -O 23506236.zip "https://www.dropbox.com/scl/fo/9jmn80tt5ekvyanntwkqx/AOESBYdNhNWShO4tro4LHpE?rlkey=k87nezuq9pxd7krcjxw6fv497&st=249odffl" &&\
        wget -q -O 23506237.zip "https://www.dropbox.com/scl/fo/1erm1nck37lt9tb3h534u/ACbQfpJ_8-hMpBiybasaaLY?rlkey=9wfqwppxxt1lqwq2l2i1x0hz8&st=v8br9gkz" &&\
        wget -q -O 23506239.zip "https://www.dropbox.com/scl/fo/s22gjyqji8fjx6dmypo1i/AHbkOsJlfj3SKeFeefRocEY?rlkey=oy4urlutk08fanoj5hw1njffl&st=0785fgi5" &&\
        wget -q -O 23511607.zip "https://www.dropbox.com/scl/fo/0v857ijnnorjf2hdxuuli/AIjVsvszotMZP995STqFc8k?rlkey=d144zybikke3j8ca7zskmq6ky&st=1mfxqwu1" &&\
        wget -q -O 23511613.zip "https://www.dropbox.com/scl/fo/ve7lo1afyn5hxks24hh7z/AECyHI542aKZWh9d1dI3Kmo?rlkey=5lkogrq4bce4ef9jbvgp9uum5&st=u830hhvw" &&\
        wget -q -O 23511614.zip "https://www.dropbox.com/scl/fo/johngi3a0ebhvm5b3qcvb/AJ3fER3ga6IK3s2EZa-C3i0?rlkey=gu5xi3czlu7ebsygpyhp0q5vj&st=emmks486" &&\
        wget -q -O weight.zip "https://www.dropbox.com/scl/fo/u8uapca0azuaf4dknxjjx/AOSO5RqGob6NFKvkjSmhlQQ?rlkey=ujd1rhehzlmpoz0yjylgdf8gs&st=2ldcfzgm"
    
    RUN sudo apt-get install unzip
    RUN sudo mkdir /app/vid && \ 
        sudo unzip /app/23506214.zip -d /app/vid/dailylife_cj611_20210903_080000.23506214 || echo "23506214.zip failed" &&\
        sudo unzip /app/23506226.zip -d /app/vid/dailylife_cj611_20210903_080000.23506226 || echo "23506226.zip failed" &&\
        sudo unzip /app/23506236.zip -d /app/vid/dailylife_cj611_20210903_080000.23506236 || echo "23506236.zip failed" &&\
        sudo unzip /app/23506237.zip -d /app/vid/dailylife_cj611_20210903_080000.23506237 || echo "23506237.zip failed" &&\
        sudo unzip /app/23506239.zip -d /app/vid/dailylife_cj611_20210903_080000.23506239 || echo "23506239.zip failed" &&\
        sudo unzip /app/23511607.zip -d /app/vid/dailylife_cj611_20210903_080000.23511607 || echo "23511607.zip failed" &&\
        sudo unzip /app/23511613.zip -d /app/vid/dailylife_cj611_20210903_080000.23511613 || echo "23511613.zip failed" &&\
        sudo unzip /app/23511614.zip -d /app/vid/dailylife_cj611_20210903_080000.23511614 || echo "23511614.zip failed" &&\
        sudo unzip weight.zip -d weight || echo "weight failed"
    
    RUN bash docker_run_test.sh
    # ENV FORCE_CUDA="0"
    # RUN pip install -r requirements/build.txt
    # RUN pip install --no-cache-dir -e .