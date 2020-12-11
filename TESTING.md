# Testing with cypress and a docker container as test env

1. Build the docker mampf container by `docker-compose -f docker-compose.local.yml build`
2. execute the tests `docker-compose -f docker-compose.local.yml run cypress_runner `
3. Review the results in console and the results in `cypress/*` folder.

## Writing own tests

The describing test files can be found/ must be placed in `spec/cypress/integration/*.js`.
You can call arbitrary functions/files in mampf by calling `cy.app("clean")` for example located in `spec/cypress/app_commands`.
Furthermore, you can setup special scenarios by providing a file in `spec/cypress/app_commands/scenarios/`,
that can be called by `cy.appScenario("setup")` for example. Always try to 
create as much as you can in the scenario and then test the interaction!

For more information visit [cypress-documentation](https://docs.cypress.io) and the used gem [cypress-on-rails](https://github.com/shakacode/cypress-on-rails) 

# Testing rspec

## In docker development container

Make sure that the seperate test db exist:

```sh
 docker-compose exec mampf  sh -c "RAILS_ENV=test  rails db:create"
  docker-compose exec mampf  sh -c "RAILS_ENV=test  rails db:migrate"
```

