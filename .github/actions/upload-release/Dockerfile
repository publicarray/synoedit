FROM alpine:latest
LABEL "com.github.actions.name"="Upload to release"
LABEL "com.github.actions.description"="Uploads files to a release."
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="blue"

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    jq \
    file

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
