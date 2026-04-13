FROM golang:1.26-alpine3.23@sha256:c2a1f7b2095d046ae14b286b18413a05bb82c9bca9b25fe7ff5efef0f0826166

ARG GHCOMMIT_VERSION=v0.1.77

# hadolint ignore=DL3018
RUN apk add --no-cache bash git-crypt curl git jq

# Download and build ghcommit from source
RUN git clone --depth 1 --branch "${GHCOMMIT_VERSION}" https://github.com/planetscale/ghcommit.git /ghcommit
WORKDIR /ghcommit
RUN go mod download
RUN CGO_ENABLED=0 go build -o /usr/bin/ghcommit .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/bin/ghcommit

ENTRYPOINT ["/entrypoint.sh"]
