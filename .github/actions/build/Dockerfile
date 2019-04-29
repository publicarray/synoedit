FROM golang:alpine3.9
LABEL "com.github.actions.name"="Build"
LABEL "com.github.actions.description"="Build spk"
LABEL "com.github.actions.icon"="code"
LABEL "com.github.actions.color"="green-dark"

RUN apk add --no-cache nodejs npm git
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
