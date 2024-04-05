FROM golang:1.22 as golang-builder
WORKDIR /workspace
# Get all dependencies
COPY go.mod .
COPY go.sum .
RUN go mod download
# Build binary
COPY . .
RUN CGO_ENABLED=0 go build -a -o noop-provisioner main.go

FROM scratch
COPY --from=golang-builder /workspace/noop-provisioner /
ENTRYPOINT ["/noop-provisioner"]
