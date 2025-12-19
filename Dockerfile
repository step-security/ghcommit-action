FROM golang:1.25.5-alpine3.23@sha256:72567335df90b4ed71c01bf91fb5f8cc09fc4d5f6f21e183a085bafc7ae1bec8

ARG GHCOMMIT_VERSION=v0.1.77

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
