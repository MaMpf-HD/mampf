FROM ruby:2.6.1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV RAILS_ENV=production

EXPOSE 3000

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0' > >(tee -a /usr/src/app/log/stdout.log) 2> >(tee -a /usr/src/app/log/stderr.log >&2)"]

# https://github.com/nodesource/distributions#installation-instructions
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -


RUN apt-get update && apt-get install -y nodejs ffmpeg imagemagick pdftk ghostscript graphviz sqlite3 cron --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY ./.delete_upload_caches.sh /etc/cron.weekly/delete_upload_caches.sh
RUN chmod 555 /etc/cron.weekly/delete_upload_caches.sh
COPY ./.destroy_expired_quizzes.sh /etc/cron.daily/destroy_expired_quizzes.sh
RUN chmod 555 /etc/cron.daily/destroy_expired_quizzes.sh
COPY ./Gemfile /usr/src/app
COPY ./Gemfile.lock /usr/src/app
RUN bundle install
COPY ./ /usr/src/app
