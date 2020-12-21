## Installation (with docker-compose)

To simply try out mampf you can use `docker-compose` ([needs docker](https://docs.docker.com/engine/install/ubuntu/) && `apt install docker-compose`). Simply clone the mampf repository and run docker-compose by executing
```
$ git clone -b main --recursive git@github.com:fosterfarrell9/mampf.git
$ cd mampf/docker/development/
# docker-compose up
```

NOTE: Please make sure to clone recursivly as the pdf compression feature is in an extra repository.
If you have an already checked out version simply run:

```sh
git submodule init
git submodule update
```

You now have the following things ready:
* The MaMpf server on <a href="http://localhost:3000/" target="_blank">localhost:3000</a>
* The mailcatcher service on <a href="http://localhost:1080/" target="_blank">localhost:1080</a>
* The webinterface for ApacheSolr on <a href="http://localhost:8983/" target="_blank">localhost:8983</a>

### Database setup

#### Use an empty database

1. register via <a href="http://localhost:3000/users/sign_up?" target="_blank">MaMpf-GUI</a>
2. visit the <a href="http://localhost:1080/" target="_blank">mailcatcher webinterface</a> and confirm your account
3. make your account admin
   ```
   # docker-compose exec mampf rails r "User.first.update(admin: true)"
   ```
4. There you go :tada:

#### Use a prefilled database

1. Download the latest version of the docker development database from <a href="https://heibox.uni-heidelberg.de/d/6fb4a9d2e7f54d8b9931/" target="_blank">here</a>
and put it in the `db/backups/docker_development` folder in your project directory. The file should have a timestamp in its name, e.g. `20201128165713_mampf.sql`
2. Restore the data from the downloaded database using the appropriate timestamp, e.g.:
   ```
   # docker-compose exec mampf rails db:restore pattern=20201128165713
   ```
3. Restore the empty interactions database and execute database migrations:
   ```
   # docker-compose exec mampf rails db:create:interactions
   # docker-compose exec mampf rails db:migrate
   ```
4. Download the sample videos and sample manuscripts that match the data in the prepopulated
	 database <a href="https://heibox.uni-heidelberg.de/f/d2f72a4069814debaf69/" target="_blank">here</a> and extract the .zip file into the `public/` folder of your project directory.
5. Call the MaMpf Server on <a href="http://localhost:3000/" target="_blank">localhost:3000</a>. The prepopulated database contains data for several users
that you can use to sign in: `admin@mampf.edu`, `teacher@mampf.edu`, `tutor@mampf.edu` and `student1@mampf.edu`,..., `student5@mampf.edu` (with the obvious roles). Each of these have `dockermampf` as password.
6. There you go :tada:


Note that in both cases, the first start of the MaMpf server can take a while, as
all assets have to provided.

A few common commands for `docker-compose` are:

| command                            | action                                                         |
|------------------------------------|----------------------------------------------------------------|
| `docker-compose up`                | runs the mampf stack                                           |
| `docker-compose up -d`             | runs the mampf stack in the background                         |
| `docker-compose logs -f`           | shows you continuous logs from the container                    |
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
PROJECT_NOTIFICATION_EMAIL= your_project_notification_email
INSTANCE_PATH=mampf
```
 3. Execute the following commands to install and run the service:
```
git clone -b main git@github.com:fosterfarrell9/mampf.git
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
