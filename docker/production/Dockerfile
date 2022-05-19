# First build the PDF compressor Web assembly binary
FROM golang:1.16 AS build-pdfcomprezzor
WORKDIR /go/src
COPY pdfcomprezzor/go.mod .
COPY pdfcomprezzor/go.sum .
COPY pdfcomprezzor/main.go .
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm

# Now build the actual mampf application
FROM ruby:3.1.2

ENV RAILS_ENV=production

EXPOSE 3000
EXPOSE 9394

ENTRYPOINT ["/usr/src/app/docker/entrypoint-worker.sh"]

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash
    # update the sources with the repos set up
RUN apt-get update
    # install all the dependencies
RUN apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript rsync shared-mime-info
RUN apt-get install -y nodejs yarn

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
    mkdir /private /caches && chown app:app /private /caches

WORKDIR /usr/src/app
USER app
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm  /usr/src/app/public/pdfcomprezzor/pdfcomprezzor.wasm

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/

RUN bundle install && \
    yarn  install --production=false
COPY --chown=app:app . /usr/src/app
RUN cp -r $(bundle info --path sidekiq)/web/assets /usr/src/app/public/sidekiq && \
    SECRET_KEY_BASE="$(bundle exec rails secret)" DB_ADAPTER=nulldb   bundle exec rails assets:precompile
