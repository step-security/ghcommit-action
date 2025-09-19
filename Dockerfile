FROM golang:1.25-alpine3.22@sha256:b6ed3fd0452c0e9bcdef5597f29cc1418f61672e9d3a2f55bf02e7222c014abd

ARG GHCOMMIT_VERSION=v0.1.75

# hadolint ignore=DL3018
RUN apk add --no-cache bash git-crypt curl git

# Download and build ghcommit from source
RUN git clone --depth 1 --branch "${GHCOMMIT_VERSION}" https://github.com/planetscale/ghcommit.git /ghcommit
WORKDIR /ghcommit
RUN go mod download
RUN CGO_ENABLED=0 go build -o /usr/bin/ghcommit .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/bin/ghcommit

ENTRYPOINT ["/entrypoint.sh"]
