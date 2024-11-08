#!/bin/bash
setup-env.sh
docker build -t sn_http -f sn_httpd.yml .
