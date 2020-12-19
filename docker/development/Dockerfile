# First build the PDF compressor Web assembly binary
FROM golang:1.15 AS build-pdfcomprezzor
WORKDIR /go/src
COPY pdfcomprezzor/go.mod .
COPY pdfcomprezzor/go.sum .
COPY pdfcomprezzor/main.go .
RUN go mod vendor
RUN sed -i 's/init(/init2(/g' vendor/github.com/pdfcpu/pdfcpu/pkg/font/metrics.go
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm

# Now build the actual mampf application
FROM ruby:2.7.2
ENV RAILS_ENV=production
EXPOSE 3000
#ENTRYPOINT [""]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    sed -i "s/deb\.debian\.org/ftp.halifax\.rwth-aachen.de/g" /etc/apt/sources.list && \
    apt-get update && apt-get install -y ffmpeg ghostscript imagemagick libarchive-tools nodejs pdftk postgresql-client-12 sqlite3 wget yarn --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && apt-get clean \
    && curl -o- -L https://yarnpkg.com/install.sh | bash

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
WORKDIR /usr/src/app

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm  /usr/src/app/public/pdfcomprezzor/pdfcomprezzor.wasm
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm  /pdfcomprezzor.wasm
COPY ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install