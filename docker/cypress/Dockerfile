FROM cypress/included:15.5.0

COPY --chmod=0755 "./docker/cypress/run-cypress-cicd.sh" "/workspaces/mampf/run-cypress-cicd.sh"
COPY --chmod=0755 "./docker/cypress/open-cypress-interactive.sh" "/workspaces/mampf/open-cypress-interactive.sh"

RUN apt-get update \
	&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
	curl x11-utils x11-xserver-utils \
	&& rm -rf /var/lib/apt/lists/*
