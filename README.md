[![Docker Build and Push](https://github.com/kontax/csgo-prac-docker/actions/workflows/docker-build-and-push.yml/badge.svg)](https://github.com/kontax/csgo-prac-docker/actions/workflows/docker-build-and-push.yml)

# csgo-training-docker

A CS2 server with [practicemod](https://github.com/splewis/csgo-practice-mode) within a docker container.
This is mostly a copy of [this container](https://github.com/kaimallea/csgo) with a couple small additions:

- Removed all plugins with the exception of practicemod and its dependencies
- Split out updating the server/plugins by including an `UPDATE_ONLY` environment variable

The reasoning behind splitting out updating and running is due to this server only being run periodically, however wanting to ensure it's up-to-date whenever being spun up. The update part runs periodically as per [csgo-prac-aws](https://github.com/kontax/csgo-prac-aws.git), whereas running the container happens manually with a script.
