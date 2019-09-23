# README

## About

MaMpf (*Mathematische Medienplattform*) is an innovative open source E-Learning platform for the mathematical sciences.
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

![thyme](public/thyme.png)

ThymE is lean and makes use of WebVTT and HTML5 video capabilites
of modern browsers. A sample hypervideo can be found
[here](https://mampf.mathi.uni-heidelberg.de/media/384/play).

MaMpf is equipped with a tagging system and rich visualisations for content relations,
making use of [cytoscape.js](http://js.cytoscape.org/).

![tags](public/tag_visualisation.png)

MaMpf has a quiz system that allows you to create complex quizzes quite easily.

![quizzes](public/quizzes.png)

MaMpf makes use of the JS based symbolic math expression evaluator
[nerdamer](https://github.com/jiggzson/nerdamer) to parse student's input in quizzes.


For more information see this [blog](https://mampfdev.wordpress.com).
There you can also find a [screenshot gallery](https://mampfdev.wordpress.com/gallery/).
## System background

MaMpf is implemented in Ruby on Rails.

* Ruby version: 2.6.3
* Rails Version: 6.0.0
* Test suite: rspec
* support for I18n

## Installation (with docker-compose)

To simply try out mampf you can use docker-compose. Simply clone the mampf repository and run docker-compose by executing
```
git clone -b master git@github.com:fosterfarrell9/mampf.git
docker-compose up
```


## Installation in production mode (with Docker)

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
ERDBEERE_SERVER = your_erdbeere_server
MUESLI_SERVER = your_muesli_server
PROJECT_EMAIL = your_project_email
MEDIA_FOLDER=mampf
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

Use the GUI to register your future admin user.
Open a rails console inside the docker container.
```
rails c
```
Give admin rights to this user:
```
User.first.update(admin: true)
```
That's it. Everything else can be done entirely via the GUI. In a production environment you might want to delete upload caches `/usr/src/app/public/uploads/cache/*` and expired quizzes (`bundle exec rake cleanup:destroy_random_quizzes`) regularly.
