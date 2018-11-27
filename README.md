# README

## About

MaMpf is an innovative open source E-Learning platform for the mathematical sciences.
Central point is the interconnection between different content in the sense
of a hypermedia system.

MaMpf uses the contextual classification of a course as visual leitmotiv,
instead of organizational aspects.

![mampf-gui](public/mampf-gui-transparent.png)

MaMpf comes with its own hypermedia player and editor THymE
(*The hypermedia Experience*). ThymeE uses the internal structure of
mathematical content (consisting of theorems, remarks, definitions etc.) and allows
exact navigation between content that is related, but temporally apart.
References can be created not only to content within the same video, but within
the whole MaMpf database.
ThymE is lean and makes use of WebVTT and HTML5 video capabilites
of modern browsers.

![thyme](public/thyme.png)

## System background

MaMpf is implemented in Ruby on Rails.

* Ruby version: 2.5.3
* Rails Version: 5.2.1
* Test suite: rspec

## Installation (with Docker)

 1. Install Database Server (e.g. PostgreSQL) and create Database.
   (Don't forget to allow access for the docker network)
```
createuser mampf
createdb -O mampf mampf
psql -c "ALTER USER mampf PASSWORD '$PASSWORD'"
```
 2. Create an environment file like this:
```
RAILS_ENV=production
PRODUCTION_DATABASE_ADAPTER=postgresql
PRODUCTION_DATABASE_DATABASE=mampf
PRODUCTION_DATABASE_USERNAME=mampf
PRODUCTION_DATABASE_PASSWORD=$DATABASE_PASSWORD
PRODUCTION_DATABASE_HOST=172.17.0.1
PRODUCTION_DATABASE_PORT=5432
MAILSERVER=localhost
FROM_ADDRESS=mampf@localhost
URL_HOST=localhost
RAILS_MASTER_KEY=$MASTER_KEY
KEKS_SERVER = your_keks_server
ERDBEERE_SERVER = your_erdbeere_server
MUESLI_SERVER = your_muesli_server
PROJECT_EMAIL = your_project_email
```
 3. Execute the following commands to install and run the service:
```
git clone -b master git@github.com:fosterfarrell9/mampf.git
docker build --label "mampf" mampf
docker create --name mampf --env-file $ENVFILE -p $OUTSIDEPORT:3000 $IMAGEID
docker run --rm --env-file $ENVFILE $IMAGEID 'rm config/credentials.yml.enc && bundle exec rails credentials:edit'
docker start mampf
docker exec mampf bundle exec rake db:migrate
docker exec mampf bundle exec rake db:seed
docker exec mampf bundle exec rake assets:precompile
docker stop mampf
docker start mampf
```
Now you can access *mampf* via `http://localhost:$OUTSIDEPORT`.

**Note**
Currently the `docker run` line is not working and the encrypted credentials file has to be replaced by hand.
