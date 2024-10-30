ARG ATHEME_UID=50000
#ARG ATHEME_VERSION=7.2.12
ARG BUILD_CONTRIB_MODULES=true

FROM alpine:latest AS builder
ARG ATHEME_VERSION
ARG BUILD_CONTRIB_MODULES
ARG MAKE_NUM_JOBS
#RUN test -n "$ATHEME_VERSION" || (echo "Please set a version to build in build arg ATHEME_VERSION" && false)

RUN mkdir /atheme-src

# Install build-deps and runtime deps
RUN apk add --no-cache \
    build-base \
    wget \
    pkgconf \
    openssl-dev \
    git

# libexecinfo is used by contrib/gen_echoserver
# RUN test -z "$BUILD_CONTRIB_MODULES" || apk add --no-cache libexecinfo-dev

# Checkout from Git - we need to manually bump the libmowgli snapshot to fix compilation against musl
# This will be fixed when 7.3 releases
#RUN wget -O atheme.tar.gz https://github.com/atheme/atheme/archive/refs/tags/v${ATHEME_VERSION}.tar.gz && tar zxvf atheme.tar.gz && mv ./atheme-${ATHEME_VERSION} ./atheme-src
RUN git clone https://github.com/atheme/atheme atheme-src --recursive && \
    cd atheme-src 
#    git fetch origin 420be30 && \
#    git checkout 420be30
RUN cd /atheme-src/libmowgli-2 && \
    git pull origin master

# 2022-02-01: build fix for alpine
RUN test -z "$BUILD_CONTRIB_MODULES" || sed -i "s/@MKDIR_P@/mkdir -p/g" /atheme-src/modules/contrib/buildsys.mk.in

# Configure and build
RUN cd /atheme-src && \
    ./configure --prefix=/atheme $(test -z "$BUILD_CONTRIB_MODULES" || echo --enable-contrib) && \
    make -j${MAKE_NUM_JOBS:-$(nproc)} && make install


FROM alpine:latest
ARG ATHEME_UID=50000
ARG BUILD_CONTRIB_MODULES=true

# openssl: used by some hashing and SASL algorithms
# msmtp: used to route mail to an external mail server
RUN apk add --no-cache openssl msmtp ca-certificates
	#  && (test -z "$BUILD_CONTRIB_MODULES" || apk add --no-cache libexecinfo)

COPY --from=builder /atheme/ /atheme

# Add custom entrypoint to check that data dir is writable - Atheme does not check this by itself
RUN echo "$ATHEME_UID" > /.atheme_uid
COPY entrypoint.sh /

RUN adduser -D -h /atheme -u $ATHEME_UID atheme
RUN chown -R atheme /atheme
USER atheme

# Services config & DB
VOLUME /atheme/etc

ENTRYPOINT ["/entrypoint.sh"]
