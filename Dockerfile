# syntax=docker/dockerfile:experimental

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# MAINTAINER iwata.koki.sd@gmail.com

# これ以降の RUN は bash -lc で動き、conda init／activate が有効になる
SHELL ["/bin/bash", "-lc"]

ENV http_proxy 'http://ufproxy.b.cii.u-fukui.ac.jp:8080'
ENV https_proxy 'http://ufproxy.b.cii.u-fukui.ac.jp:8080'

RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install -y sudo wget && apt-get install -y git

# install miniconda env
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    sh Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-latest-Linux-x86_64.sh

ENV PATH /opt/miniconda3/bin:$PATH

# COPY <env_file_name>.yml .

RUN pip install --upgrade pip && \
    conda update -n base -c defaults conda && \
    conda create -n temp python=3.10.12 && \
    conda init && \
    echo "conda activate temp" >> ~/.bashrc

WORKDIR /

ENV PATH=/opt/miniconda3/envs/temp/bin:/opt/miniconda3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118 && \
    # Open mmlab
    pip install openmim==0.3.9 && \
    mim install mmcv-full==1.6.2 && \
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

# repository and minor or local resources
RUN git clone https://github.com/c7h2y/marmo3Dpose.git
RUN pip install imgstore==0.2.9
WORKDIR /marmo3Dpose
RUN pip install 'src/m_lib'

# Install MMPose
# RUN conda clean --all

RUN git checkout dev

RUN wget -O 23506214.zip "https://www.dropbox.com/scl/fo/37q4kv0avrqnio77j2m45/AHBCjGDSomz8lBDKgqZ0TSc?rlkey=x10kl3ybojetw8uk7obhaxld2&st=hzv5pkhe" &&\
    wget -O 23506226.zip "https://www.dropbox.com/scl/fo/a9p0psdwbaxlepizn5ffa/ALwuW-HiEATMIeLBoRGs5oo?rlkey=yziwod48z7z5vnnuri20zw795&st=0f2pcjus" &&\
    wget -O 23506236.zip "https://www.dropbox.com/scl/fo/9jmn80tt5ekvyanntwkqx/AOESBYdNhNWShO4tro4LHpE?rlkey=k87nezuq9pxd7krcjxw6fv497&st=249odffl" &&\
    wget -O 23506237.zip "https://www.dropbox.com/scl/fo/1erm1nck37lt9tb3h534u/ACbQfpJ_8-hMpBiybasaaLY?rlkey=9wfqwppxxt1lqwq2l2i1x0hz8&st=v8br9gkz" &&\
    wget -O 23506239.zip "https://www.dropbox.com/scl/fo/s22gjyqji8fjx6dmypo1i/AHbkOsJlfj3SKeFeefRocEY?rlkey=oy4urlutk08fanoj5hw1njffl&st=0785fgi5" &&\
    wget -O 23511607.zip "https://www.dropbox.com/scl/fo/0v857ijnnorjf2hdxuuli/AIjVsvszotMZP995STqFc8k?rlkey=d144zybikke3j8ca7zskmq6ky&st=1mfxqwu1" &&\
    wget -O 23511613.zip "https://www.dropbox.com/scl/fo/ve7lo1afyn5hxks24hh7z/AECyHI542aKZWh9d1dI3Kmo?rlkey=5lkogrq4bce4ef9jbvgp9uum5&st=u830hhvw" &&\
    wget -O 23511614.zip "https://www.dropbox.com/scl/fo/johngi3a0ebhvm5b3qcvb/AJ3fER3ga6IK3s2EZa-C3i0?rlkey=gu5xi3czlu7ebsygpyhp0q5vj&st=emmks486" &&\
    wget -O weight.zip "https://www.dropbox.com/scl/fo/u8uapca0azuaf4dknxjjx/AOSO5RqGob6NFKvkjSmhlQQ?rlkey=ujd1rhehzlmpoz0yjylgdf8gs&st=2ldcfzgm"

RUN apt-get install unzip &&\
    mkdir vid &&\
    unzip 23506214.zip -d vid/dailylife_cj611_20210903_080000.23506214 || echo "23506214.zip failed" &&\
    unzip 23506226.zip -d vid/dailylife_cj611_20210903_080000.23506226 || echo "23506226.zip failed" &&\
    unzip 23506236.zip -d vid/dailylife_cj611_20210903_080000.23506236 || echo "23506236.zip failed" &&\
    unzip 23506237.zip -d vid/dailylife_cj611_20210903_080000.23506237 || echo "23506237.zip failed" &&\
    unzip 23506239.zip -d vid/dailylife_cj611_20210903_080000.23506239 || echo "23506239.zip failed" &&\
    unzip 23511607.zip -d vid/dailylife_cj611_20210903_080000.23511607 || echo "23511607.zip failed" &&\
    unzip 23511613.zip -d vid/dailylife_cj611_20210903_080000.23511613 || echo "23511613.zip failed" &&\
    unzip 23511614.zip -d vid/dailylife_cj611_20210903_080000.23511614 || echo "23511614.zip failed" &&\
    unzip weight.zip -d weight || echo "weight failed"

RUN bash docker_run_test.sh
# ENV FORCE_CUDA="0"
# RUN pip install -r requirements/build.txt
# RUN pip install --no-cache-dir -e .