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
FROM ruby:3.4.7-bookworm

ARG RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.app.github.dev"
ENV RAILS_DEVELOPMENT_HOSTS=${RAILS_DEVELOPMENT_HOSTS}

# use "--login" option, so that .bashrc is sourced in new shells
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Install Node.js
# https://github.com/nodesource/distributions/issues/1583#issuecomment-1597489401
# https://stackoverflow.com/a/57546198/
# Unfortunately, we have to explicitly specify the node version here
# and cannot use 24.x as we need to put the node binary into the PATH
# and therefore require the exact version to find the folder
ENV NODE_VERSION=24.11.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
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
# yarn available instead of our specified version
RUN yarn set version "${YARN_VERSION}"

# Make Node.js tooling available for other users
# see https://www.digitalocean.com/community/tutorials/how-to-install-node-js-with-nvm-node-version-manager-on-a-vps
# this command copies the currently active nvm node tooling to /usr/local/
# so that it can be used by the app user later
RUN n=$(which node); n=${n%/bin/node}; chmod 755 $n/bin/node; chmod 755 $n/bin/yarn; cp -r $n/{bin,lib,share} /usr/local

# Install other dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        ffmpeg imagemagick pdftk ghostscript shared-mime-info \
        libarchive-tools wget wait-for-it graphviz libvips42 lsof

# Playwright system dependencies
RUN npx playwright install-deps chromium

# Install PostgreSQL client 17 (https://wiki.postgresql.org/wiki/Apt)
RUN mkdir -p /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list" \
    && apt-get update \
    && apt-get install -y postgresql-client-17

# Setup ImageMagick
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

# 🎈 Users
# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user
ARG USERNAME=mampf
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user & setup permissions
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /cache && chown -R $USERNAME /cache \
    && mkdir -p /workspaces/mampf/node_modules/ && chown -R $USERNAME /workspaces/mampf/node_modules/ \
    && mkdir -p /workspaces/mampf/public/ && chown -R $USERNAME /workspaces/mampf/public/ \
    && mkdir -p /workspaces/mampf/public/uploads/ && chown -R $USERNAME /workspaces/mampf/public/uploads/ \
    # [Optional] Add sudo support
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 🎈 Finally, set up the app
WORKDIR /workspaces/mampf/
ENTRYPOINT ["/workspaces/mampf/docker/development/init-and-run.sh"]
USER $USERNAME

# Log Node.js tooling versions
RUN which node && node --version && which yarn && yarn --version

COPY --chown=$USERNAME Gemfile Gemfile.lock package.json yarn.lock /workspaces/mampf/
COPY --chown=$USERNAME --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /workspaces/mampf/public/pdfcomprezzor/
COPY --chown=$USERNAME --from=build-pdfcomprezzor /go/src/pdfcomprezzor.wasm /go/src/wasm_exec.js /

ARG CI_BUILD
RUN if [ "$CI_BUILD" = "true" ]; then \
        echo "Running bundle install"; \
        bundle install; \
    fi
# https://stackoverflow.com/a/66158709/9655481
RUN if [ "$CI_BUILD" = "true" ]; then \
        echo "Running yarn install"; \
        yarn install --frozen-lockfile; \
    fi

# Playwright browser
# (--no-shell to avoid downloading the old headless mode)
RUN npx playwright install chromium --no-shell

# Precompile assets in CI/CD
# (See the production Dockerfile for an explanation of the dummy env file)
COPY --chown=$USERNAME . /workspaces/mampf/
RUN if [ "$CI_BUILD" = "true" ]; then \
        echo "Compiling MaMpf assets in pipeline"; \
        mkdir -p /workspaces/mampf/coverage/ && chown -R $USERNAME /workspaces/mampf/coverage/; \
        set -o allexport; . ./docker/production/docker.env; set +o allexport; \
        SECRET_KEY_BASE="$(bundle exec rails secret)" \
        VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL=true \
        RAILS_ENV=test DATABASE_ADAPTER=nulldb \
        bundle exec rails assets:precompile; \
    fi
