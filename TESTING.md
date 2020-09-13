# Testing with cypress and a docker container as test env

1. Start the docker-container with `docker-compose up` in `docker/run_cypress_tests`
2. Start Cypress via `yarn cypress open --project ./spec` (install it before hand with `yarn`)
3. execute the tests

TODO: automatic run inside of the docker container.