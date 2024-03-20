#!/usr/bin/env bash

cd /usr/src/app

./initialize.sh &> >(tee -a /usr/src/app/log/initialisation.log)

rm -f tmp/pids/server.pid
bin/rails server -e test -p 3000

# in separate window start cypress
yarn cypress open --project ./specs
