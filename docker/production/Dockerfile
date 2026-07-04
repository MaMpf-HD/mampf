# Build args shared across stages. Docker scopes ARGs per stage, so each stage
# below re-declares the ones it needs (bare `ARG NAME`) to inherit these defaults.
# This single-sources the versions/paths that must stay in sync across stages.
ARG BUNDLER_VERSION=4.0.12
ARG BUNDLE_PATH=/usr/local/bundle
ARG BUNDLE_WITHOUT="development:test"

FROM node:24.11.0-trixie-slim AS node

FROM ruby:3.4.9-slim-trixie AS build

ARG BUNDLER_VERSION
ARG BUNDLE_PATH
ARG BUNDLE_WITHOUT
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}" \
    BUNDLE_PATH="${BUNDLE_PATH}"

ARG OR_TOOLS_VERSION=or-tools-9.15-trixie
ARG OR_TOOLS_FILENAME=or-tools-9.15-trixie-amd64.tar.gz
ARG OR_TOOLS_SHA256=067e96ba57bbca8bf8e56c9b85010e223d49696cb5fe1a56ef94f5bd3647c0cf

SHELL ["/bin/bash", "--login", "-c"]

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

# Install build-time and runtime dependencies.
# build-essential/git/pkg-config are needed to compile native gem extensions
# (bcrypt, bindex, msgpack, nio4r, puma, sassc) and to clone git-sourced gems.
# The remaining packages are runtime deps also needed here so that Rails can
# boot during assets:precompile.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        pkg-config \
        libyaml-dev \
        ffmpeg rsync shared-mime-info libvips42 && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v "${BUNDLER_VERSION}"

# Download OR-Tools for Debian 13 (the or-tools gem has no official trixie
# binary yet; see https://github.com/MaMpf-HD/build-artifacts)
ADD --checksum=sha256:${OR_TOOLS_SHA256} https://github.com/MaMpf-HD/build-artifacts/releases/download/${OR_TOOLS_VERSION}/${OR_TOOLS_FILENAME} /tmp/or-tools.tar.gz
RUN mkdir -p /opt/or-tools && tar xzf /tmp/or-tools.tar.gz -C /opt/or-tools && rm /tmp/or-tools.tar.gz

WORKDIR /usr/src/app

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app

COPY ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json ./.yarnrc.yml /usr/src/app/
RUN bundle config set --local build.or-tools --with-or-tools-dir=/opt/or-tools
RUN bundle install
RUN yarn install --immutable

COPY . /usr/src/app

RUN chmod 755 /usr/src/app/docker/production/entrypoint-app.sh \
    /usr/src/app/docker/production/entrypoint-sidekiq.sh

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
    bundle exec rails assets:precompile && \
    rm -f ./docker-dummy.env && \
    rm -rf node_modules tmp/cache && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/bundler/gems/*/.git && \
    rm -rf /usr/local/bundle/cache /usr/local/bundle/ruby/*/cache && \
    find /usr/local/bundle -name "*.gem" -delete

FROM ruby:3.4.9-slim-trixie

ARG BUNDLER_VERSION
ARG BUNDLE_PATH
ARG BUNDLE_WITHOUT
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}" \
    BUNDLE_PATH="${BUNDLE_PATH}" \
    APP_HEALTHCHECK_PORT=3000 \
    APP_CACHE_ROOT=/caches

ENTRYPOINT ["/usr/src/app/docker/production/entrypoint-app.sh"]

# Empty in normal (reproducible) builds; `just patch-image` passes a unique value
# to bust this layer and apply all available Debian security updates on top of the
# (force-pulled) base image.
ARG OS_SECURITY_REFRESH=
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg qpdf rsync shared-mime-info libvips42 && \
    if [ -n "${OS_SECURITY_REFRESH}" ]; then apt-get upgrade -y; fi && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v "${BUNDLER_VERSION}"

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
        mkdir -p /private/media /private/submissions "${APP_CACHE_ROOT}" \
      /usr/src/app/tmp/pids /usr/src/app/log && \
        chown -R app:app /private "${APP_CACHE_ROOT}"

WORKDIR /usr/src/app

COPY --from=node /usr/local/ /usr/local/
COPY --from=build --chown=root:root /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=root:root /usr/src/app /usr/src/app
COPY --from=build /opt/or-tools/lib /opt/or-tools/lib

RUN chown -R app:app /usr/src/app/tmp /usr/src/app/log && \
        rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack \
            /usr/local/bin/yarn /usr/local/bin/yarnpkg \
            /usr/src/app/bin/yarn && \
        rm -rf /usr/local/lib/node_modules/npm \
            /usr/local/lib/node_modules/corepack && \
    rm -rf /usr/local/bundle/cache

USER app

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD ruby -rnet/http -e 'port = ENV.fetch("APP_HEALTHCHECK_PORT", "3000"); uri = URI("http://127.0.0.1:#{port}/up"); response = Net::HTTP.start(uri.host, uri.port) { |http| http.get(uri.request_uri, {"X-Forwarded-Proto" => "https", "Host" => "localhost"}) }; exit(response.is_a?(Net::HTTPSuccess) ? 0 : 1)'
