#!/bin/bash

source build_variables

docker build --pull \
    --build-arg "WGT_GIT_REF=${WGT_GIT_REF}" \
    --tag "${IMAGE_NAME}:latest" \
    build
