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
EXPOSE 9394

# use "--login" option, so that .bashrc is sourced in new shells
SHELL ["/bin/bash", "--login", "-c"] 

# Install Node.js
# https://github.com/nodesource/distributions/issues/1583#issuecomment-1597489401
# https://stackoverflow.com/a/57546198/
# Unfortunately, we have to explicitly specify the node version here
# and cannot use 16.x as we need to put the node binary into the PATH
# and therefore require the exact version to find the folder
ENV NODE_VERSION=16.20.1
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN source $NVM_DIR/nvm.sh && nvm install ${NODE_VERSION} && \
    nvm use ${NODE_VERSION} && nvm alias default ${NODE_VERSION}

ENV NODE_PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin"
ENV PATH="${NODE_PATH}:${PATH}"

RUN nvm current
RUN node --version
RUN npm --version

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y lsb-release && \
    # https://wiki.postgresql.org/wiki/Apt
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install --no-install-recommends -y ffmpeg ghostscript imagemagick \
            libarchive-tools pdftk postgresql-client-13 sqlite3 wget \
            wait-for-it yarn shared-mime-info && \
    rm -rf /var/lib/apt/lists/* && apt-get clean

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml
WORKDIR /usr/src/app
ENTRYPOINT ["./entrypoint.sh"]

COPY ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /
