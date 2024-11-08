FROM golang:1.17.3 AS build

ADD ./irccat/ /go/src/github.com/irccloud/irccat/
WORKDIR /go/src/github.com/irccloud/irccat/

RUN CGO_ENABLED=0 go get -t -v ./... && go build -a .

# Step two: copy over the binary and root certs
FROM alpine:3.18

# Create a user with UID and GID 50000
RUN addgroup -g 50000 irccatgroup && adduser -u 50000 -G irccatgroup -s /bin/sh -D irccatuser

# Copy the built binary and root certs
COPY --from=build /go/bin/irccat /irccat 
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

RUN apk fix && \
     apk --no-cache --update add git python3 py3-setuptools py3-twisted

COPY ./misc /misc

# Change ownership to the created user
RUN chown -R irccatuser:irccatgroup /irccat /misc

USER irccatuser

EXPOSE 12345
EXPOSE 8045

CMD ["/irccat"]

