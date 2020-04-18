FROM ruby:2.7.1

ENV RAILS_ENV=production

EXPOSE 3000
VOLUME /public

ENTRYPOINT ["/usr/src/app/docker/entrypoint-worker.sh"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn ffmpeg imagemagick pdftk ghostscript sqlite3 rsync --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app && \
      mkdir /mampf
WORKDIR /usr/src/app
USER app

COPY --chown=app:app ./Gemfile ./Gemfile.lock /usr/src/app/
RUN bundle install
COPY --chown=app:app ./ /usr/src/app
RUN SECRET_KEY_BASE="$(bundle exec rails secret)" DB_ADAPTER=nulldb   bundle exec rails assets:precompile
RUN echo "test" > public/test
