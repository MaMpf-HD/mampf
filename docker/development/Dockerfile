FROM ruby:2.7.1

ENV RAILS_ENV=production

EXPOSE 3000

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn ffmpeg imagemagick pdftk ghostscript sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 501 app && useradd -g 501 -u 501 -m -d /usr/src/app app
WORKDIR /usr/src/app
USER app

COPY --chown=app:app ./Gemfile /usr/src/app
COPY --chown=app:app ./Gemfile.lock /usr/src/app
RUN bundle install
COPY --chown=app:app ./ /usr/src/app

