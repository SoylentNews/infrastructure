#!/bin/bash

# This script is a placeholder to conform to the convention that
# ./build.sh builds and tags a service's Docker image.

# To use this, you would create a Dockerfile for a service. For example,
# if you create a 'grafana/Dockerfile' to build a custom grafana image:
#
# source ../util/setup-env.sh
# docker build -t your-repo/custom-grafana:latest ./grafana
#

echo "No custom images to build for the monitoring service."
exit 0