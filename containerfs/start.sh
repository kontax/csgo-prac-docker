#!/usr/bin/env bash
 
# These envvars should've been set by the Dockerfile
# If they're not set then something went wrong during the build
: "${STEAM_DIR:?'ERROR: STEAM_DIR IS NOT SET!'}"
: "${STEAMCMDDIR:?'ERROR: STEAMCMDDIR IS NOT SET!'}"
: "${STEAM_APP_ID:?'ERROR: STEAM_APP_ID IS NOT SET!'}"


# If the update envvar is set, then only update the CS instance
# and shutdown the container.
if [[ $UPDATE_ONLY -eq 1 ]]; then
    echo -e "\n[*] Updating CS and exiting"
    [[ -z ${CI+x} ]] && \
    "$STEAMCMDDIR/steamcmd.sh" \
        +force_install_dir "$STEAM_DIR" \
        +login anonymous \
        +app_update "$STEAM_APP_ID" \
        +quit

    # Install and configure plugins & extensions
    echo -e "\n[*] Updating or installing plugins"
    "$BASH" "$HOMEDIR/manage_plugins.sh"

    echo -e "\n[*] Finished updating CS"
    exit 0
fi

# If the delete envvar is set, then delete everything in the csgo folder
# and shutdown the container.
if [[ $DELETE_ALL -eq 1 ]]; then
    echo -e "\n[*] Deleting data from volumne and exiting"
    echo -e "\n$ ls -a $STEAM_DIR"
    ls -a $STEAM_DIR
    rm -r $STEAM_DIR/*

    echo -e "\n[*] Finished deleting CS data from the volume"
    exit 0
fi

# set_env_from_file_or_def VAR [DEFAULT]
# e.g. set_env_from_file_or_def 'RCON_PASSWORD' 'test'
# Fills $VAR either with the content of the file with the name $VAR_FILE
# or with DEFAULT. 
# If $VAR is already set nothing will be changed
# If both $VAR and $VAR_FILE are set $VAR will keep its value and content
# of $VAR_FILE will be ignored.
function set_env_from_file_or_def() {
    local VAR="$1"
    local FILEVAR="${VAR}_FILE"
    local DEFAULTVAL="${2:-}"
    local RETURNVAL="$DEFAULTVAL"

    if [ "${!VAR:-}" ]; then
        RETURNVAL="${!VAR}"
    elif [ "${!FILEVAR:-}" ]; then
        RETURNVAL="$(< "${!FILEVAR}")"
    fi

    export "$VAR"="$RETURNVAL"
    unset "$FILEVAR"
}

export SERVER_HOSTNAME="${SERVER_HOSTNAME:-Counter-Strike: Global Offensive Dedicated Server}"
set_env_from_file_or_def 'SERVER_PASSWORD'
set_env_from_file_or_def 'RCON_PASSWORD' 'changeme'
set_env_from_file_or_def 'STEAM_ACCOUNT' 'changeme'
set_env_from_file_or_def 'AUTHKEY' 'changeme'
set_env_from_file_or_def 'IP' '0.0.0.0'
export PORT="${PORT:-27015}"
export TV_PORT="${TV_PORT:-27020}"
export TICKRATE="${TICKRATE:-128}"
export FPS_MAX="${FPS_MAX:-400}"
export GAME_TYPE="${GAME_TYPE:-0}"
export GAME_MODE="${GAME_MODE:-1}"
export MAP="${MAP:-de_dust2}"
export MAPGROUP="${MAPGROUP:-mg_active}"
export HOST_WORKSHOP_COLLECTION="${HOST_WORKSHOP_COLLECTION:-}"
export WORKSHOP_START_MAP="${WORKSHOP_START_MAP:-}"
export MAXPLAYERS="${MAXPLAYERS:-12}"
export TV_ENABLE="${TV_ENABLE:-1}"
export LAN="${LAN:-0}"
set_env_from_file_or_def 'SOURCEMOD_ADMINS'
export RETAKES="${RETAKES:-0}"
export ANNOUNCEMENT_IP="${ANNOUNCEMENT_IP:-}"
export NOMASTER="${NOMASTER:-}"


# Create dynamic autoexec config
mkdir -p "$STEAM_DIR/game/csgo/cfg"

if [ ! -s "$STEAM_DIR/game/csgo/cfg/autoexec.cfg" ]; then
cat << AUTOEXECCFG > "$STEAM_DIR/game/csgo/cfg/autoexec.cfg"
log on
hostname "$SERVER_HOSTNAME"
rcon_password "$RCON_PASSWORD"
sv_password "$SERVER_PASSWORD"
sv_cheats 0
exec banned_user.cfg
exec banned_ip.cfg
AUTOEXECCFG

else
sed -i "s/^hostname.*/hostname \"$SERVER_HOSTNAME\"/" $STEAM_DIR/game/csgo/cfg/autoexec.cfg
sed -i "s/^rcon_password.*/rcon_password \"$RCON_PASSWORD\"/" $STEAM_DIR/game/csgo/cfg/autoexec.cfg
sed -i "s/^sv_password.*/sv_password \"$SERVER_PASSWORD\"/" $STEAM_DIR/game/csgo/cfg/autoexec.cfg

fi

# Create dynamic server config
if [ ! -s "$STEAM_DIR/game/csgo/cfg/server.cfg" ]; then
cat << SERVERCFG > "$STEAM_DIR/game/csgo/cfg/server.cfg"
sv_setsteamaccount "$STEAM_ACCOUNT"
tv_enable $TV_ENABLE
tv_delaymapchange 1
tv_delay 30
tv_deltacache 2
tv_dispatchmode 1
tv_maxclients 10
tv_maxrate 0
tv_overridemaster 0
tv_relayvoice 1
tv_snapshotrate 64
tv_timeout 60
tv_transmitall 1
writeid
writeip
sv_mincmdrate $TICKRATE
sv_maxupdaterate $TICKRATE
sv_minupdaterate $TICKRATE
SERVERCFG

else
sed -i "s/^tv_enable.*/tv_enable $TV_ENABLE/" $STEAM_DIR/game/csgo/cfg/server.cfg

fi

SRCDS_ARGUMENTS=(
  "-dedicated"
  "-console"
  "-usercon"
  "-autoupdate"
  "-authkey $AUTHKEY"
  "-steam_dir $STEAMCMDDIR"
  "-steamcmd_script $HOMEDIR/autoupdate_script.txt"
  "-port $PORT"
  "-net_port_try 1"
  "-ip $IP"
  "-maxplayers_override $MAXPLAYERS"
  "+fps_max $FPS_MAX"
  "+game_type $GAME_TYPE"
  "+game_mode $GAME_MODE"
  "+mapgroup $MAPGROUP"
  "+map $MAP"
  "+sv_setsteamaccount" "$STEAM_ACCOUNT"
  "+sv_lan $LAN"
  "+tv_port $TV_PORT"
)

if [[ -n $HOST_WORKSHOP_COLLECTION ]]; then
  SRCDS_ARGUMENTS+=("+host_workshop_collection $HOST_WORKSHOP_COLLECTION")
fi

if [[ -n $WORKSHOP_START_MAP ]]; then
  SRCDS_ARGUMENTS+=("+workshop_start_map $WORKSHOP_START_MAP")
fi

if [[ -n $ANNOUNCEMENT_IP ]]; then
  SRCDS_ARGUMENTS+=("+net_public_adr $ANNOUNCEMENT_IP")
fi

if [[ $NOMASTER == 1 ]]; then
  SRCDS_ARGUMENTS+=("-nomaster")
fi

SRCDS_RUN="$STEAM_DIR/game/bin/linuxsteamrt64/cs2"

# Patch srcds_run to fix autoupdates
if grep -q 'steam.sh' "$SRCDS_RUN"; then
  sed -i 's/steam.sh/steamcmd.sh/' "$SRCDS_RUN"
  echo "[*] Applied patch to srcds_run to fix autoupdates"
fi

# Start the server
eval "$SRCDS_RUN" "${SRCDS_ARGUMENTS[@]}"
