#!/usr/bin/env bash
# bash ./dockerbld_withproxy.sh $http_proxy .

proxy=$1
mount=$2
IMAGE_NAME="marmo:latest"

echo "=== 1. docker build ==="
sudo docker build --build-arg http_proxy="${proxy}"   --build-arg https_proxy="${proxy}" -t "${IMAGE_NAME}" .

echo "=== 2. viddata and weight download then unzip ==="
wget -nc -O viddata.zip "https://www.dropbox.com/scl/fi/zfs5t5wx0iga0pcq8oagv/viddata.zip?rlkey=ur8w6z4cd2vfu7dtc3j0cunn6&st=is3e1jhs"
wget -nc -O weight.zip  "https://www.dropbox.com/scl/fo/u8uapca0azuaf4dknxjjx/AOSO5RqGob6NFKvkjSmhlQQ?rlkey=ujd1rhehzlmpoz0yjylgdf8gs&st=2ldcfzgm"

sudo unzip -n viddata.zip || echo "viddata failed"
sudo unzip -n weight.zip -d weight || echo "weight failed"

echo "=== 3. docker run ==="
sudo docker run --rm -it --gpus all \
    -v ${mount}/viddata:/app/marmo3Dpose/vid \
    -v ${mount}/weight:/app/marmo3Dpose/weight \
    -v ${mount}/work_dir:/app/marmo3Dpose/work \
    "${IMAGE_NAME}" bash
