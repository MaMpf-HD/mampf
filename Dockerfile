FROM ruby:2.4.0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV RAILS_ENV=production

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

RUN apt-get update && apt-get install -y nodejs sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY ./ /usr/src/app
RUN bundle install
