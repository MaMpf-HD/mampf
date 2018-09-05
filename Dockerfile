FROM ruby:2.5.0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV RAILS_ENV=production

EXPOSE 3000

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0' > >(tee -a /usr/src/app/log/stdout.log) 2> >(tee -a /usr/src/app/log/stderr.log >&2)"]

RUN apt-get update && apt-get install -y nodejs ffmpeg imagemagick ghostscript graphviz sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY ./ /usr/src/app
RUN bundle install
