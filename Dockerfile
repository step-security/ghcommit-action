FROM golang:1.25.2-alpine3.22@sha256:06cdd34bd531b810650e47762c01e025eb9b1c7eadd191553b91c9f2d549fae8

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
