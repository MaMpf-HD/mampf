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

ENTRYPOINT ["/usr/src/app/docker/entrypoint-worker.sh"]

SHELL ["/bin/bash","--login", "-c"] 

# Install Node.js
# https://github.com/nodesource/distributions/issues/1583#issuecomment-1597489401
# https://stackoverflow.com/a/57546198/9655481
ENV NODE_VERSION=16.20.1
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version
RUN npm --version

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
# update the sources with the repos set up
RUN apt-get update
# install all the dependencies
RUN apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript rsync shared-mime-info
RUN apt-get install -y yarn

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
    mkdir /private /caches && chown app:app /private /caches

WORKDIR /usr/src/app
USER app
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/

RUN bundle install && \
    yarn  install --production=false
COPY --chown=app:app . /usr/src/app
RUN cp -r $(bundle info --path sidekiq)/web/assets /usr/src/app/public/sidekiq && \
    SECRET_KEY_BASE="$(bundle exec rails secret)" DB_ADAPTER=nulldb   bundle exec rails assets:precompile
