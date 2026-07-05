# syntax=docker/dockerfile:1-labs
# check=error=true
# ADD --checksum needs the labs frontend (above); # syntax must be the very first
# line, so parser directives come before this comment.
# https://docs.docker.com/build/checks/#fail-build-on-check-violations

FROM node:24.11.0-trixie-slim AS node

# Now build the actual MaMpf application
# https://hub.docker.com/_/ruby/
FROM ruby:3.4.10-trixie

ARG RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.app.github.dev"
ARG BUNDLER_VERSION=4.0.12
ARG OR_TOOLS_VERSION=or-tools-9.15-trixie
ARG OR_TOOLS_FILENAME=or-tools-9.15-trixie-amd64.tar.gz
ARG OR_TOOLS_SHA256=067e96ba57bbca8bf8e56c9b85010e223d49696cb5fe1a56ef94f5bd3647c0cf

# Development images expose the same generic runtime contract as production:
# APP_HEALTHCHECK_PORT is the public HTTP port for the current stack and
# APP_CACHE_ROOT is writable cache space for runtime-specific state.
ENV RAILS_DEVELOPMENT_HOSTS=${RAILS_DEVELOPMENT_HOSTS} \
    APP_HEALTHCHECK_PORT=3000 \
    APP_CACHE_ROOT=/cache

# use "--login" option, so that .bashrc is sourced in new shells
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Install Node.js
COPY --from=node /usr/local/ /usr/local/

RUN node --version
RUN npm --version

# Install Yarn (see https://yarnpkg.com/getting-started/install)
# https://github.com/nodejs/corepack#corepack-prepare--nameversion
ENV YARN_VERSION=4.17.0
RUN rm -f /usr/local/bin/yarn /usr/local/bin/yarnpkg && corepack enable
RUN corepack prepare "yarn@${YARN_VERSION}" --activate
RUN which yarn; yarn --version

# Install other dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        ffmpeg qpdf shared-mime-info \
        libarchive-tools wget wait-for-it graphviz libvips42 lsof \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v "${BUNDLER_VERSION}"

# Allow Bundler to use its bare git cache with newer Git defaults.
RUN git config --system safe.bareRepository all

# Download OR-Tools for Debian 13 (the or-tools gem has no official trixie
# binary yet; see https://github.com/MaMpf-HD/build-artifacts)
ADD --checksum=sha256:${OR_TOOLS_SHA256} https://github.com/MaMpf-HD/build-artifacts/releases/download/${OR_TOOLS_VERSION}/${OR_TOOLS_FILENAME} /tmp/or-tools.tar.gz
RUN mkdir -p /opt/or-tools \
    && tar xzf /tmp/or-tools.tar.gz -C /opt/or-tools \
    && rm /tmp/or-tools.tar.gz

# Playwright system dependencies
RUN npx playwright install-deps chromium

# Install PostgreSQL client 18 (https://wiki.postgresql.org/wiki/Apt)
  RUN mkdir -p /usr/share/postgresql-common/pgdg \
      && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      && . /etc/os-release \
      && sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list" \
      && apt-get update \
      && apt-get install -y postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*

# 🎈 Users
# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user
ARG USERNAME=mampf
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user & setup permissions
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /usr/local/bundle && chown -R $USERNAME /usr/local/bundle \
    && mkdir -p /cache && chown -R $USERNAME /cache \
    # yarn 4 creates .yarn/ in the workspace root during CI_BUILD; the non-root user must own the dir itself
    && mkdir -p /workspaces/mampf && chown $USERNAME /workspaces/mampf \
    && mkdir -p /workspaces/mampf/node_modules/ && chown -R $USERNAME /workspaces/mampf/node_modules/ \
    && mkdir -p /workspaces/mampf/public/ && chown -R $USERNAME /workspaces/mampf/public/ \
    && mkdir -p /workspaces/mampf/public/uploads/ && chown -R $USERNAME /workspaces/mampf/public/uploads/ \
    # Pre-create the Claude Code data dir so the fresh named volume mounted
    # here (see compose.devcontainer.yml) inherits mampf ownership instead of
    # being root-owned. Avoids a chown workaround on every rebuild.
    && mkdir -p /workspaces/claude && chown -R $USERNAME /workspaces/claude \
    # [Optional] Add sudo support
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# 🎈 Finally, set up the app
WORKDIR /workspaces/mampf/
ENTRYPOINT ["/workspaces/mampf/docker/development/init-and-run.sh"]
USER $USERNAME

RUN bundle config set --global build.or-tools --with-or-tools-dir=/opt/or-tools

# Log Node.js tooling versions
RUN which node && node --version && which yarn && yarn --version

COPY --chown=$USERNAME Gemfile Gemfile.lock package.json yarn.lock .yarnrc.yml /workspaces/mampf/

ARG CI_BUILD
RUN if [ "$CI_BUILD" = "true" ]; then \
        echo "Running bundle install"; \
        bundle install; \
    fi
# https://stackoverflow.com/a/66158709/9655481
RUN if [ "$CI_BUILD" = "true" ]; then \
        echo "Running yarn install"; \
    yarn install --immutable; \
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
