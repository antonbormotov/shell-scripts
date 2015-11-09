#!/bin/bash


IP=XXX
USER=XXX
PASS=XXX
DIR=/iprice/${USER}

list=$(curl -sS -u ${USER}:${PASS} ftp://${IP}/ | grep csv | sed 's/\([A-Za-z]\)\s\([A-Za-z]\)/\1%20\2/g' | awk '{print $9}' | awk '$1=$1' ORS=' ')

for f in ${list}
do
    sudo curl -sS --create-dirs --output "${DIR}/${f}" -u ${USER}:${PASS} "ftp://${IP}/${f}"
done

sudo chown -vR ${USER}:${USER} ${DIR}
exit 0

