# https://docs.docker.com/build/checks/#fail-build-on-check-violations
# check=error=true

# 🎈 Stage for Node.js tooling
FROM node:24.15-trixie AS node-tooling

ENV YARN_VERSION=1.22.22
ENV COREPACK_HOME=/usr/local/share/corepack

RUN corepack enable && \
    corepack prepare "yarn@${YARN_VERSION}" --activate && \
    yarn --version

# 🎈 Stage for PDF compressor (Web assembly binary)
# this is adapted from https://github.com/henrixapp/pdfcomprezzor/blob/master/Dockerfile
FROM golang:1.24-bookworm AS build-pdfcomprezzor
WORKDIR /go/src
COPY --from=node-tooling /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
COPY pdfcomprezzor/go.mod pdfcomprezzor/go.sum pdfcomprezzor/main.go ./
RUN GOOS=js GOARCH=wasm go build -o pdfcomprezzor.wasm
RUN cp "$(go env GOROOT)/lib/wasm/wasm_exec.js" .

# 🎈 Stage for Ruby and actual MaMpf application
FROM ghcr.io/mampf-hd/mampf-ruby-hardened:4.0-dev

ARG RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.app.github.dev"
ENV RAILS_DEVELOPMENT_HOSTS=${RAILS_DEVELOPMENT_HOSTS}

# use "--login" option, so that .bashrc is sourced in new shells
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Install Node.js tooling
ENV COREPACK_HOME=/usr/local/share/corepack
COPY --from=node-tooling /usr/local/bin/node /usr/local/bin/node
COPY --from=node-tooling /usr/local/include/node /usr/local/include/node
COPY --from=node-tooling /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node-tooling /usr/local/share/corepack /usr/local/share/corepack
RUN ln -sf ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -sf ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack && \
    ln -sf ../lib/node_modules/corepack/dist/yarn.js /usr/local/bin/yarn && \
    ln -sf ../lib/node_modules/corepack/dist/yarnpkg.js /usr/local/bin/yarnpkg && \
    chmod -R a+rX /usr/local/lib/node_modules "${COREPACK_HOME}" && \
    node --version && npm --version && yarn --version

# Install packages required by MaMpf itself
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        ffmpeg ghostscript imagemagick libarchive-tools libvips42 lsof \
        pdftk shared-mime-info wait-for-it \
    && rm -rf /var/lib/apt/lists/*

# Install packages intended for local development and debugging
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        bzip2 ca-certificates curl git graphviz gzip jq less \
        libpam-runtime ncurses-bin ncurses-term openssh-client ripgrep \
        sudo tar tree unzip wget xz-utils \
    && /usr/sbin/pam-auth-update --package --force \
    && test -f /etc/pam.d/common-auth \
    && test -f /etc/pam.d/common-account \
    && test -f /etc/pam.d/common-session \
    && test -f /etc/pam.d/common-session-noninteractive \
    && rm -rf /var/lib/apt/lists/*

# Playwright system dependencies
RUN npx playwright install-deps chromium && rm -rf /var/lib/apt/lists/*

# Install PostgreSQL client 17 (https://wiki.postgresql.org/wiki/Apt)
RUN export DEBIAN_FRONTEND=noninteractive \
    && mkdir -p /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list" \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

# Setup ImageMagick
RUN policy_file=$(find /etc -path '*/ImageMagick-*/policy.xml' | head -n 1) \
    && sed -i '/disable ghostscript format types/,+6d' "$policy_file"

RUN touch /etc/ld.so.cache && /sbin/ldconfig

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
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 🎈 Finally, set up the app
WORKDIR /workspaces/mampf/
ENTRYPOINT ["/workspaces/mampf/docker/development/init-and-run.sh"]
USER $USERNAME

# Log Node.js tooling versions
RUN command -v node && node --version && command -v yarn && yarn --version

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
