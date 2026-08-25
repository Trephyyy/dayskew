FROM golang:1.22

WORKDIR /repo

COPY . .

RUN go build -o /out/server ./cmd/server

EXPOSE 8080

CMD ["/out/server"]