#!/bin/bash -eE

DEBUG=${DEBUG:-no}

if [ "$DEBUG" = "yes" ]; then
    set -x
fi

## -------------- Enviroments-----------------------

export EMAIL_FOR_NOTIFICATIONS="mail@zerospace.xyz"
HOSTNAME=$(hostname -f)
export CLEAN_HOST=${CLEAN_HOST:-yes}
export TON_Q_SERVER_GITHUB_REPO="https://github.com/tonlabs/ton-q-server"
export TON_Q_SERVER_GITHUB_COMMIT_ID="0.52.1"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
export SCRIPT_DIR
SRC_TOP_DIR=$(cd "${SCRIPT_DIR}/../" && pwd -P)
export SRC_TOP_DIR
export DOCKER_COMPOSE_DIR="${SRC_TOP_DIR}/docker-compose"
export COMPOSE_HTTP_TIMEOUT=120

## ---------------- Docker install-------------------

#echo "INFO: install dependencies..."
#sudo apt update
#sudo apt install -y \
#    docker-compose \
#    git
#echo "INFO: install dependencies... DONE"


set +eE

for BUNDLE_COMPONENT in proxy web.root q-server; do
    if [ "${CLEAN_HOST}" = "yes" ]; then
        cd "${DOCKER_COMPOSE_DIR}/${BUNDLE_COMPONENT}/" && docker-compose down --volumes --remove-orphans
    else
        cd "${DOCKER_COMPOSE_DIR}/${BUNDLE_COMPONENT}/" && docker-compose stop
    fi
done

if [ "${CLEAN_HOST}" = "yes" ]; then
    docker system prune --all --force --volumes
    docker network create proxy_nw
fi

set -eE




## web.root compose
sed -i "s|host.yourdomain.com|${HOSTNAME}|g" "${DOCKER_COMPOSE_DIR}/web.root/.env"
sed -i "s|for notification|${EMAIL_FOR_NOTIFICATIONS}|g" "${DOCKER_COMPOSE_DIR}/web.root/docker-compose.yml"

## proxy compose
rm -f "${DOCKER_COMPOSE_DIR}/proxy/htpasswd/arango.yourdomain.com"
echo "admin:\$apr1\$d0ifqbt3\$iayulpIOP2.IS4Sy1I2zJ0" >"${DOCKER_COMPOSE_DIR}/proxy/htpasswd/arango.${HOSTNAME}"
echo "#iJJ9fWxb9Z6CS1aPagoW" >>"${DOCKER_COMPOSE_DIR}/proxy/htpasswd/arango.${HOSTNAME}"
mv "${DOCKER_COMPOSE_DIR}/proxy/vhost.d/host.yourdomain.com" "${DOCKER_COMPOSE_DIR}/proxy/vhost.d/${HOSTNAME}"

for BUNDLE_COMPONENT in proxy web.root; do
    cd "${DOCKER_COMPOSE_DIR}/${BUNDLE_COMPONENT}/" && docker-compose up -d
done


## q-server compose
rm -rf "${DOCKER_COMPOSE_DIR}/q-server/build/ton-q-server"
rm -rf "${DOCKER_COMPOSE_DIR}/q-server/build/ton-q-server"
cd "${DOCKER_COMPOSE_DIR}/q-server/build" && git clone --recursive "${TON_Q_SERVER_GITHUB_REPO}"
cd "${DOCKER_COMPOSE_DIR}/q-server/build/ton-q-server" && git checkout "${TON_Q_SERVER_GITHUB_COMMIT_ID}"
cd "${DOCKER_COMPOSE_DIR}/q-server" && docker-compose up -d