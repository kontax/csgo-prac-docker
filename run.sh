docker run \
  --rm \
  --interactive \
  --tty \
  --detach \
  --mount source=cs2-data,target=/home/steam/cs2-dedicated \
  --network=host \
  --env "SERVER_HOSTNAME=hostname" \
  --env "SERVER_PASSWORD=password" \
  --env "RCON_PASSWORD=rconpassword" \
  --env "STEAM_ACCOUNT=gamelogintoken" \
  --env "AUTHKEY=webapikey" \
  --env "SOURCEMOD_ADMINS=STEAM_1:0:123456,STEAM_1:0:654321" \
  couldinho/csgo-prac-docker
