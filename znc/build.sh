#!/bin/bash
docker build -t znc:slim -f ./znc-docker/slim/Dockerfile ./znc-docker/slim/
docker build -t znc:full -f ./znc-docker/full/Dockerfile ./znc-docker/full/
