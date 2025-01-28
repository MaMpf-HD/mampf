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
FROM ruby:3.1.4-bullseye

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
# Note that postgresql-client-13 is available through debian bullseye
# that the ruby image is based on
RUN apt update && \
    apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript shared-mime-info \
        libarchive-tools postgresql-client-13 wget wait-for-it graphviz

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
RUN if [ "$IN_CI_CD" = "true" ]; then \
        echo "Running yarn install"; \
        yarn install; \
    fi

    
# Precompile assets in CI/CD
# (See the production Dockerfile for an explanation of the dummy env file)
# (NODE_ENVtest-ci to trigger respective webpacker.yml section)
COPY . /usr/src/app/
RUN if [ "$IN_CI_CD" = "true" ]; then \
        echo "Compiling all assets yeah again to better path"; \
        set -o allexport; . ./docker/production/docker.env; set +o allexport; \
        SECRET_KEY_BASE="$(bundle exec rails secret)" \
        DB_ADAPTER=nulldb NODE_ENV=test-ci bundle exec rails assets:precompile; \
    fi

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/
COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /
