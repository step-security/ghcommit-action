FROM golang:1.26-alpine3.23@sha256:27f829349da645e287cb195a9921c106fc224eeebbdc33aeb0f4fca2382befa6

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
