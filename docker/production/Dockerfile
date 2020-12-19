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

ENTRYPOINT ["/usr/src/app/docker/entrypoint-worker.sh"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn ffmpeg imagemagick pdftk ghostscript sqlite3 rsync --no-install-recommends && rm -rf /var/lib/apt/lists/* 


RUN curl -sL https://deb.nodesource.com/setup_14.x | bash \
 && apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/* \
 && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
 && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
 && apt-get update && apt-get install -y yarn && rm -rf /var/lib/apt/lists/*


RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
      mkdir /private /caches && chown app:app /private /caches
WORKDIR /usr/src/app
USER app
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm  /usr/src/app/public/pdfcomprezzor/pdfcomprezzor.wasm

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/

RUN bundle install
RUN yarn  install --production=false
COPY --chown=app:app . /usr/src/app
RUN cp -r /usr/local/bundle/gems/sidekiq-6.1.2/web/assets /usr/src/app/public/sidekiq
RUN SECRET_KEY_BASE="$(bundle exec rails secret)" DB_ADAPTER=nulldb   bundle exec rails assets:precompile
