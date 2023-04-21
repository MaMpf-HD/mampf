FROM ruby:3.1.2

ENV RAILS_ENV=production

EXPOSE 3000

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y nodejs yarn ffmpeg imagemagick pdftk ghostscript sqlite3 shared-mime-info --no-install-recommends && rm -rf /var/lib/apt/lists/* && apt-get clean

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app
WORKDIR /usr/src/app
USER app

COPY --chown=app:app ./Gemfile ./Gemfile.lock ./yarn.lock ./package.json /usr/src/app/
RUN bundle install && yarn install --production=false
RUN bundle exec rails webpacker:install webpacker:compile

COPY --chown=app:app ./ /usr/src/app/
