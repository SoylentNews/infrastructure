#!/bin/bash
set -e

if [ -z $LISTEN ]; then
  LISTEN=3333
fi
echo "$1 some stuff"
if [[ "$1" = *".conf" ]]; then
  # allow the container to be started with `--user`
  if [ "$(id -u)" = '0' ]; then
    echo "ran as root"
    chown -R eggdrop /home/eggdrop/eggdrop .
    exec su-exec eggdrop "$BASH_SOURCE" "$@"
  fi

  CONFIG=$1

  cd /home/eggdrop/eggdrop
  if ! [ -e /home/eggdrop/eggdrop/data/${CONFIG} ] && ([ -z ${SERVER} ] || [ -z ${NICK} ]); then
    echo "no ${CONFIG} ${SERVER} ${NICK}"
    cat <<EOS >&2


EOS
    exit 1
  fi

  if ! mountpoint -q /home/eggdrop/eggdrop/data; then
    cat <<EOS


EOS
  fi
  
### Check if previous config file is present and, if not, create one
  mkdir -p /home/eggdrop/eggdrop/data
  if ! [ -e /home/eggdrop/eggdrop/data/${CONFIG} ]; then
    echo "making a conf"
    echo "Previous Eggdrop config file not detected, creating new persistent data file..."
    sed -i \
      -e "/set nick \"Lamestbot\"/c\set nick \"$NICK\"" \
      -e "/another.example.com 7000:password/d" \
      -e "/you.need.to.change.this 6667/c\server add ${SERVER}" \
      -e "/#listen 3333 all/c\listen ${LISTEN} all" \
      -e "s/^#set dns-servers/set dns-servers/" \
      -e "/#set owner \"MrLame, MrsLame\"/c\set owner \"${EGGOWNER}\"" \
      -e "/set userfile \"LamestBot.user\"/c\set userfile data/${USERFILE}" \
      -e "/set chanfile \"LamestBot.chan\"/c\set chanfile data/${CHANFILE}" \
      -e "/set realname \"\/msg LamestBot hello\"/c\set realname \"Docker Eggdrop!\"" \
      -e '/edit your config file completely like you were told/d' \
      -e '/Please make sure you edit your config file completely/d' eggdrop.conf
      echo "server add ${SERVER}" >> eggdrop.conf
      echo "if {[catch {source scripts/docker.tcl} err]} {" >> eggdrop.conf
      echo "  putlog \"INFO: Could not load docker.tcl file\"" >> eggdrop.conf
      echo "  putlog \"Error: \$err\"" >> eggdrop.conf
      echo "}" >> eggdrop.conf
      mv /home/eggdrop/eggdrop/eggdrop.conf /home/eggdrop/eggdrop/data/${CONFIG}
  else
    echo "removing eggdrop if it exists"
    if [ -e /home/eggdrop/eggdrop/eggdrop.conf ]; then
      rm /home/eggdrop/eggdrop/eggdrop.conf
    fi
  fi
  echo "${CONFIG} ing it and linking data/${CONFIG} to /${CONFIG}"
  ln -sf /home/eggdrop/eggdrop/data/${CONFIG} /home/eggdrop/eggdrop/${CONFIG}

### Check for existing userfile and create link to data dir as backup
  USERFILE=$(grep "set userfile " ${CONFIG} |cut -d " " -f 3|cut -d "\"" -f 2)
  echo "Makey user ${USERFILE}"
  if [ -e /home/eggdrop/eggdrop/data/${USERFILE} ]; then
    ln -sf /home/eggdrop/eggdrop/data/${USERFILE} /home/eggdrop/eggdrop/${USERFILE}
  fi


### Check for existing channel file and create link to data dir as backup
  CHANFILE=$(grep "set chanfile " ${CONFIG} |cut -d " " -f 3|cut -d "\"" -f 2)
  echo "Makey chan ${CHANFILE}"
  if [ -e /home/eggdrop/eggdrop/data/${CHANFILE} ]; then
    ln -sf /home/eggdrop/eggdrop/data/${CHANFILE} /home/eggdrop/eggdrop/${CHANFILE}
  fi


### Remove previous pid file, if present
  PID=$(grep "set pidfile" ${CONFIG})
  if [[ $PID == \#* ]]; then
    PIDNEXT=$(grep "set botnet-nick" ${CONFIG})
    if [[ $PIDNEXT == \#* ]]; then
      PIDNEXT=$(grep "set nick" ${CONFIG})
    fi
    PIDBASE=$(echo $PIDNEXT|awk '{gsub("\"", "", $3); print $3}')
    PID=$(echo pid.$PIDBASE)
  else
    PID=$(echo $PID|awk '{gsub("\"", "", $3); print $3}')
  fi
  if [ -e "$PID" ]; then
    PID="${PID//\"}"
    echo "Found $PID, removing..."
    rm $PID;
  fi

  exec ./eggdrop -nt -m ${CONFIG}
fi
exec "$@"
