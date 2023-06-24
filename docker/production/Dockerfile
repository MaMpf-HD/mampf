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
RUN source "${NVM_DIR}/nvm.sh" && nvm install "${NODE_VERSION}" && \
    nvm use "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"

ENV NODE_PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/"
ENV PATH="${NODE_PATH}:${PATH}"

RUN nvm current
RUN node --version
RUN npm --version

# Make Node.js tooling available for other users
# see https://www.digitalocean.com/community/tutorials/how-to-install-node-js-with-nvm-node-version-manager-on-a-vps
# this command copies the currently active nvm node version to /usr/local/ directory
# so that it can be used by the app user later
RUN n=$(which node); n=${n%/bin/node}; chmod 755 $n/bin/node; cp -r $n/{bin,lib,share} /usr/local

# Install Yarn (see https://yarnpkg.com/getting-started/install)
# https://github.com/nodejs/corepack#corepack-prepare--nameversion
RUN corepack enable
RUN corepack prepare yarn@stable --activate --output "/usr/local/yarn-corepack.tgz"

# Install other dependencies
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript rsync shared-mime-info

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
    mkdir /private /caches && chown app:app /private /caches


# ============= Now switch to the app user
WORKDIR /usr/src/app
USER app

# Activate yarn
RUN corepack hydrate /usr/local/yarn-corepack.tgz --activate

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install
RUN yarn plugin import workspace-tools
RUN yarn workspaces focus --production

COPY --chown=app:app . /usr/src/app
RUN cp -r $(bundle info --path sidekiq)/web/assets /usr/src/app/public/sidekiq && \
    SECRET_KEY_BASE="$(bundle exec rails secret)" DB_ADAPTER=nulldb   bundle exec rails assets:precompile
