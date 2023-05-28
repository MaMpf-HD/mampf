# First build the PDF compressor Web assembly binary
# this is adapted from https://github.com/henrixapp/pdfcomprezzor/blob/master/Dockerfile
FROM golang:1.20 AS build-pdfcomprezzor
WORKDIR /go/src
COPY pdfcomprezzor/go.mod pdfcomprezzor/go.sum pdfcomprezzor/main.go ./
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm
RUN cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" .

# Now build the actual mampf application
FROM ruby:3.1.4
ENV RAILS_ENV=production
EXPOSE 3000

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y ffmpeg ghostscript imagemagick \
            libarchive-tools nodejs pdftk postgresql-client-13 sqlite3 wget \
            wait-for-it yarn shared-mime-info && \
    rm -rf /var/lib/apt/lists/* && apt-get clean

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
WORKDIR /usr/src/app

COPY ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install && \
    yarn  install --production=false

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /

COPY  ./ /usr/src/app/
RUN RAILS_ENV=test TEST_DATABASE_ADAPTER=postgresql rake assets:precompile
