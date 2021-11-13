docker run \
  --rm \
  --interactive \
  --tty \
  --mount type=bind,source=$(pwd)/csgo-data,target=/home/steam/csgo \
  --network=host \
  --env "UPDATE_ONLY=1" \
  --env "SOURCEMOD_ADMINS=STEAM_1:0:123456" \
  couldinho/csgo-prac-docker
