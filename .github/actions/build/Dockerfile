FROM golang:alpine3.9
LABEL "com.github.actions.name"="Build"
LABEL "com.github.actions.description"="Build spk"
LABEL "com.github.actions.icon"="code"
LABEL "com.github.actions.color"="green-dark"

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
