#!/bin/sh

USERNAME=reza
PASSWORD=
USERHOME=/home/${USERNAME}

sudo useradd -U -m -d ${USERHOME} -s /bin/bash ${USERNAME}
#echo ${USERNAME}:${PASSWORD} | sudo chpasswd

sudo -u ${USERNAME} sh -c "\
    ssh-keygen -t rsa -N \"\" -f ${USERHOME}/.ssh/id_rsa &&\
    cp -v ${USERHOME}/.ssh/id_rsa.pub ${USERHOME}/.ssh/authorized_keys &&\
    chmod -v 600 ${USERHOME}/.ssh/authorized_keys"

exit 0

