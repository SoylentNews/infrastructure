#!/bin/bash
setup-env.sh
docker build -t sn_bender -f ./bender/Dockerfile ./bender/
