FROM ruby:2.7.1

ENV RAILS_ENV=production

EXPOSE 3000

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    sed -i "s/deb\.debian\.org/ftp.halifax\.rwth-aachen.de/g" /etc/apt/sources.list && \
    apt-get update && apt-get install -y nodejs yarn postgresql-client-12 ffmpeg imagemagick pdftk ghostscript sqlite3 wget --no-install-recommends && rm -rf /var/lib/apt/lists/* && apt-get clean

WORKDIR /usr/src/app

COPY ./Gemfile ./Gemfile.lock /usr/src/app/
RUN bundle install
