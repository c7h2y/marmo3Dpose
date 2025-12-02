#!/usr/bin/env bash

IMAGE_NAME="marmo:test"

echo "=== 1. docker build ==="
docker build -t "${IMAGE_NAME}" .

echo "=== 2. docker run ==="
docker run -it "${IMAGE_NAME}" bash