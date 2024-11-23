#!/bin/bash
cp hc.dockerfile ./healthchecks/docker/
docker build -t hc -f ./healthchecks/docker/hc.dockerfile ./healthchecks/
