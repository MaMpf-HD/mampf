# https://docs.docker.com/build/checks/#fail-build-on-check-violations
# check=error=true

# First build the PDF compressor Web assembly binary
# this is adapted from https://github.com/henrixapp/pdfcomprezzor/blob/master/Dockerfile
FROM golang:1.20 AS build-pdfcomprezzor
WORKDIR /go/src
COPY pdfcomprezzor/go.mod pdfcomprezzor/go.sum pdfcomprezzor/main.go ./
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm
RUN cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" .

# Now build the actual MaMpf application
# https://hub.docker.com/_/ruby/
FROM ruby:3.3.8-bookworm

EXPOSE 3000
EXPOSE 9394

# use "--login" option, so that .bashrc is sourced in new shells
SHELL ["/bin/bash", "--login", "-c"]

# Install Node.js
# https://github.com/nodesource/distributions/issues/1583#issuecomment-1597489401
# https://stackoverflow.com/a/57546198/
# Unfortunately, we have to explicitly specify the node version here
# and cannot use 20.x as we need to put the node binary into the PATH
# and therefore require the exact version to find the folder
ENV NODE_VERSION=20.10.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN source "${NVM_DIR}/nvm.sh" && nvm install "${NODE_VERSION}" && \
    nvm use "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"

ENV NODE_PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/"
ENV PATH="${NODE_PATH}:${PATH}"

RUN nvm current
RUN node --version
RUN npm --version

# Install Yarn (see https://yarnpkg.com/getting-started/install)
# https://github.com/nodejs/corepack#corepack-prepare--nameversion
ENV YARN_VERSION=1.22.19
RUN corepack enable
RUN corepack prepare "yarn@${YARN_VERSION}" --activate
RUN which yarn; yarn --version
# even though this is not specified in the corepack documentation, we need to
# run "set version", otherwise the app user will have an old version of
# yarn available instead of our specified version
RUN yarn set version "${YARN_VERSION}"

# Install other dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript shared-mime-info \
        libarchive-tools wget wait-for-it graphviz libvips42

# Install PostgreSQL client 17 (https://wiki.postgresql.org/wiki/Apt)
RUN mkdir -p /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list" \
    && apt-get update \
    && apt-get install -y postgresql-client-17

# Setup ImageMagick
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

WORKDIR /usr/src/app
ENTRYPOINT ["/usr/src/app/docker/entrypoint-dev-test.sh"]

COPY ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
ARG IN_CI_CD
RUN if [ "$IN_CI_CD" = "true" ]; then \
        echo "Running bundle install"; \
        bundle install; \
    fi
# https://stackoverflow.com/a/66158709/9655481
RUN if [ "$IN_CI_CD" = "true" ]; then \
        echo "Running yarn install"; \
        yarn install --frozen-lockfile; \
    fi

# Precompile assets in CI/CD
# (See the production Dockerfile for an explanation of the dummy env file)
COPY . /usr/src/app/
RUN if [ "$IN_CI_CD" = "true" ]; then \
        echo "Compiling MaMpf assets in pipeline"; \
        set -o allexport; . ./docker/production/docker.env; set +o allexport; \
        SECRET_KEY_BASE="$(bundle exec rails secret)" \
        VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL=true \
        RAILS_ENV=test DB_ADAPTER=nulldb DATABASE_URL="" \
        bundle exec rails assets:precompile; \
    fi

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /
