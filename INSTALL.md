## Installation (with docker-compose)

To simply try out mampf you can use `docker-compose` ([needs docker](https://docs.docker.com/engine/install/ubuntu/) && `apt install docker-compose`). Simply clone the mampf repository and run docker-compose by executing
```
$ git clone -b master git@github.com:fosterfarrell9/mampf.git
$ cd mampf/docker/development/
# docker-compose up
```

You now have the following things ready:
* The MaMpf server on <a href="http://localhost:3000/" target="_blank">localhost:3000</a>
* The mailcatcher service on <a href="http://localhost:1080/" target="_blank">localhost:1080</a>
* The webinterface for ApacheSolr on <a href="http://localhost:8983/" target="_blank">localhost:8983</a>

Now you are just a few steps away from having an admin account on your local MaMpf instance:
1. register via <a href="http://localhost:3000/users/sign_up?" target="_blank">MaMpf-GUI</a>
2. visit the <a href="http://localhost:1080/" target="_blank">mailcatcher webinterface</a> and confirm your account
3. make your account admin
   ```
   # docker-compose exec mampf rails r "User.first.update(admin: true)"
   ```
4. There you go :tada:

A few common commands for `docker-compose` are:

| command                            | action                                                         |
|------------------------------------|----------------------------------------------------------------|
| `docker-compose up`                | runs the mampf stack                                           |
| `docker-compose up -d`             | runs the mampf stack in the background                         |
| `docker-compose logs -f`           | shows you continuos logs from the container                    |
| `docker-compose down`              | deletes all the created containers                             |
| `docker-compose down --volumes`    | deletes all the associated containers and volumes (full reset) |
| `docker-compose exec mampf <exec>` | run an executable in the container

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
