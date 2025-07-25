# First build the PDF compressor Web assembly binary
# this is adapted from https://github.com/henrixapp/pdfcomprezzor/blob/master/Dockerfile
FROM golang:1.20 AS build-pdfcomprezzor
WORKDIR /go/src
COPY pdfcomprezzor/go.mod pdfcomprezzor/go.sum pdfcomprezzor/main.go ./
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm
RUN cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" .

# Now build the actual mampf application
# https://hub.docker.com/_/ruby/
FROM ruby:3.3.8-bookworm

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
# and cannot use 20.x as we need to put the node binary into the PATH
# and therefore require the exact version to find the folder
ENV NODE_VERSION=20.10.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN source "${NVM_DIR}/nvm.sh" && nvm install "${NODE_VERSION}" && \
    nvm use "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"

ENV NODE_PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/"
ENV PATH="${NODE_PATH}:${PATH}"

RUN nvm current; node --version
RUN npm --version

# Install Yarn (see https://yarnpkg.com/getting-started/install)
# https://github.com/nodejs/corepack#corepack-prepare--nameversion
ENV YARN_VERSION=1.22.19
RUN corepack enable
RUN corepack prepare "yarn@${YARN_VERSION}" --activate
RUN which yarn; yarn --version
# even though this is not specified in the corepack documentation, we need to
# run "set version", otherwise the app user will have an old version of
# yarn avaialble instead of our specified version
RUN yarn set version "${YARN_VERSION}"

# Make Node.js tooling available for other users
# see https://www.digitalocean.com/community/tutorials/how-to-install-node-js-with-nvm-node-version-manager-on-a-vps
# this command copies the currently active nvm node tooling to /usr/local/
# so that it can be used by the app user later
RUN n=$(which node); n=${n%/bin/node}; chmod 755 $n/bin/node; chmod 755 $n/bin/yarn; cp -r $n/{bin,lib,share} /usr/local

# Install other dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript rsync shared-mime-info libvips42

# Setup ImageMagick
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

# Manage users
RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
    mkdir /private /caches && chown app:app /private /caches


# ============= Now switch to the app user
WORKDIR /usr/src/app
USER app

# Log Node.js tooling versions that the `app` user uses
RUN which node; node --version; which yarn; yarn --version

COPY --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /usr/src/app/public/pdfcomprezzor/

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install
RUN yarn install --frozen-lockfile

COPY --chown=app:app . /usr/src/app

# The command ". ./docker-dummy.env" will source our dummy docker env file.
# So why do we need this?
#
# Well, (deeply inhales), Rails needs to boot entirely to run the
# `assets:precompile` task. Therefore, it also needs to access the env variables
# to correctly start the initializers.
#
# However (after a long time researching), docker compose does not seem to offer
# an easy solution to have an env file from the host machine available during
# the build step (Dockerfile) and not just during the run time of the container.
# Note that the env file is indeed available on our host, just not in the build
# context, the latter being the MaMpf github repo that docker compose pulls from.
#
# Even with volumes and bind mounts it's not working properly ("file not found").
# In the end, we found a solution that suggests to use the new docker buildkit
# to allow for multiple build contexts. Yet, we explicitly set DOCKER_BUILDKIT=0
# to use the old buildkit since the new one always gives a moby-related ssh error.
# And even if this worked, it is not entirely clear if this is even working
# with docker compose or just with docker (sigh).
#
# That's why, in the end, we decided to leverage our already-existing dummy env
# file and source it here in the Dockerfile just to have the precompile task run
# successfully (this task doesn't even rely on the actual values, so despite
# being a hack, it should be fine).
#
# I've written down more details in this question on StackOverflow:
# https://stackoverflow.com/q/78098380/
COPY ./docker/production/docker.env ./docker-dummy.env

RUN cp -r $(bundle info --path sidekiq)/web/assets /usr/src/app/public/sidekiq && \
    set -o allexport && . ./docker-dummy.env && set +o allexport && \
    SECRET_KEY_BASE="$(bundle exec rails secret)" \
    VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL=true \
    RAILS_ENV=production DATABASE_ADAPTER=nulldb \
    bundle exec rails assets:precompile
