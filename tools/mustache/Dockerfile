FROM golang:1.21-alpine

RUN go install github.com/cbroglie/mustache/cmd/mustache@v1.4.0

ENTRYPOINT [ "mustache" ]