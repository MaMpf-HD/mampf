## Installation (with docker compose)

To simply try out mampf you can use `docker compose` (needs [Docker](https://docs.docker.com/engine/install/) and [Docker Compose](https://docs.docker.com/compose/install/)). Simply clone the MaMpf repository and run docker compose by executing
```
$ git clone -b main --recursive https://github.com/MaMpf-HD/mampf.git
$ cd mampf/docker/development/
# docker compose up
```

NOTE: Please make sure to clone recursively as the pdf compression feature is in a separate repository.

If you have an already checked out version simply run:
```
git submodule update --init
```

You now have the following things ready:
* The MaMpf server on [localhost:3000](http://localhost:3000/)
* The mailcatcher service on [localhost:1080](http://localhost:1080/)
* The webinterface for ApacheSolr on [localhost:8983](http://localhost:8983/)
* A test mailserver instance on Ports 1025, 10143, 10993
* A webpacker dev server on [localhost:3035](http://localhost:3035/)

### Database setup

#### Using a prefilled database

After setting up everything you can call the MaMpf Server on <a href="http://localhost:3000/" target="_blank">localhost:3000</a>. The prepopulated database contains data for several users that you can use to sign in (with the obvious roles). Each of these have `dockermampf` as password.:

- `admin@mampf.edu`
- `teacher@mampf.edu`
- `tutor@mampf.edu`
- `student1@mampf.edu`,..., `student5@mampf.edu`

##### Prefilled database: automatic setup

Just uncomment the lines containing `DB_SQL_PRESEED_URL` and `UPLOADS_PRESEED_URL` in the development docker-compose.yml, start Mampf and you should be good to go after it finished initialising.
After the first initialization is done you should comment them again, otherwise the DB will be reset on each container start.
If that for some reason does not work, open a [new issue](https://github.com/MaMpf-HD/mampf/issues/new) about it and follow the manual setup instead.

##### Prefilled database: Manual setup

1. Download the latest version of the docker development database from <a href="https://heibox.uni-heidelberg.de/d/6fb4a9d2e7f54d8b9931/" target="_blank">here</a>
and put it in the `db/backups/docker_development` folder in your project directory. The file should have a timestamp in its name, e.g. `20220923120841_mampf.sql`
2. Restore the data from the downloaded database using the appropriate timestamp, e.g.:
   ```
   # docker compose exec mampf rails db:restore pattern=20220923120841
   ```
3. Restore the empty interactions database and execute database migrations:
   ```
   # docker compose exec mampf rails db:create:interactions
   # docker compose exec mampf rails db:migrate
   ```
4. Download the sample videos and sample manuscripts that match the data in the prepopulated
     database <a href="https://heibox.uni-heidelberg.de/f/1c4804dcd78446139fd9/?dl=1" target="_blank">here</a> and extract the .zip file into the `public/` folder of your project directory.

Note that in both cases, the first start of the MaMpf server can take a while, as
all assets have to provided.

#### Using an empty database

1. register via <a href="http://localhost:3000/users/sign_up?" target="_blank">MaMpf-GUI</a>
2. visit the <a href="http://localhost:1080/" target="_blank">mailcatcher webinterface</a> and confirm your account
3. make your account admin
   ```
   # docker compose exec mampf rails r "User.first.update(admin: true)"
   ```
4. There you go :tada:

### Common docker compose commands

A few common commands for `docker compose` are:

| command                            | action                                                         |
| ---------------------------------- | -------------------------------------------------------------- |
| `docker compose up`                | runs the mampf stack                                           |
| `docker compose up -d`             | runs the mampf stack in the background                         |
| `docker compose logs -f`           | shows you continuous logs from the container                   |
| `docker compose down`              | deletes all the created containers                             |
| `docker compose down --volumes`    | deletes all the associated containers and volumes (full reset) |
| `docker compose exec mampf <exec>` | run an executable in the container                             |

If you installed docker compose as a plugin to docker these commands are instead prefixed with `docker compose` (note the space).


## Installation in production mode

 1. Install Database Server (e.g. PostgreSQL) and create Database.
   (Don't forget to allow access for the docker network)
```
createuser -P mampf
createdb -O mampf mampf
```
 2. Create an environment file based on the example in docker/production/docker.env
 3. Create a docker-compose file based on docker/production/docker-compose.production.yml . We recommend serving upload caches, submissions and media files by a separate server. They communicate with Mampf using NFS as Docker volumes. See the example options in the sample file.
 4. Launch MaMpf using `docker compose up -d`
 5. (Optional) Scale MaMpf horizontally by spawning more workers `docker compose scale worker=5`
  Now you can access *mampf* via `http://localhost:$OUTSIDEPORT`.

Use the GUI to register your future admin user.
Open a rails console inside the docker container.
```
docker compose exec master rails c
```
Give admin rights to this user:
```
User.first.update(admin: true)
```
That's it. Everything else can be done entirely via the GUI.
