# syntax=docker/dockerfile:experimental

FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

RUN apt-get update && apt-get install -y \
    sudo \
    wget

# install miniconda env
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    sh Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-latest-Linux-x86_64.sh

ENV PATH /opt/miniconda3/bin:$PATH

# COPY <env_file_name>.yml .

RUN pip install --upgrade pip && \
    conda update -n base -c defaults conda && \
    conda env create -n temp python=3.10.12 && \
    conda init && \
    echo "conda activate temp" >> ~/.bashrc

RUN pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118

# Open mmlab
RUN pip install openmim==0.3.9O
RUN mim install mmcv-full==1.6.2
RUN mim install mmpose==0.29.0
RUN mim install mmdet==2.26.0
RUN mim install mmtrack==0.14.0
RUN mim install mmcls==0.25.0
RUN pip install xtcocotools==1.12

# Major tools
RUN pip install opencv-contrib-python==4.8.1.78
RUN pip install numba==0.58.0
RUN pip install h5py==3.9.0
RUN pip install pyyaml==6.0.1
RUN pip install toml==0.10.2 
RUN pip install matplotlib==3.8.0
RUN pip install joblib==1.3.2

# repository and minor or local resources
RUN git clone git@github.com:c7h2y/marmo3Dpose.git
RUN pip install imgstore==0.2.9
RUN cd /marmo3Dpose && pip install 'src/m_lib'

# Install MMPose
RUN conda clean --all

WORKDIR /marmo3Dpose
RUN git checkout main
ENV FORCE_CUDA="1"
RUN pip install -r requirements/build.txt
RUN pip install --no-cache-dir -e .