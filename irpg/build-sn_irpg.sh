#!/bin/bash
setup-env.sh
docker build -t sn_irpg -f ./sn_irpg/Dockerfile ./sn_irpg/
