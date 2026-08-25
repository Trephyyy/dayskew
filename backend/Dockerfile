FROM golang:1.22

WORKDIR /repo

COPY . .

RUN go:build
RUN go:build -o out/migrate cmd/migrate

CMD go:run