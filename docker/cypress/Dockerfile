FROM cypress/included:15.5.0

COPY --chmod=0755 "./docker/cypress/run-cypress-cicd.sh" "/workspaces/mampf/run-cypress-cicd.sh"
COPY --chmod=0755 "./docker/cypress/open-cypress-interactive.sh" "/workspaces/mampf/open-cypress-interactive.sh"

RUN apt-get update && apt-get install curl -y
