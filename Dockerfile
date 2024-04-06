FROM golang:1.22 as golang-builder
WORKDIR /workspace
# Get all dependencies
COPY go.mod .
COPY go.sum .
RUN go mod download
# Build binary
COPY main.go .
RUN CGO_ENABLED=0 go build -a -o noop-provisioner main.go

FROM alpine:3.19
COPY --from=golang-builder /workspace/noop-provisioner /usr/local/bin/
ENTRYPOINT ["noop-provisioner"]
