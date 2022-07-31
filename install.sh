echo "INFO: install dependencies..."
sudo apt update
sudo apt install -y \
    docker-compose \
    git
echo "INFO: install dependencies... DONE"


rm -rf "${DOCKER_COMPOSE_DIR}/q-server/build/ton-q-server"
cd "${DOCKER_COMPOSE_DIR}/q-server/build" && git clone --recursive "${TON_Q_SERVER_GITHUB_REPO}"
cd "${DOCKER_COMPOSE_DIR}/q-server/build/ton-q-server" && git checkout "${TON_Q_SERVER_GITHUB_COMMIT_ID}"
cd "${DOCKER_COMPOSE_DIR}/q-server" && docker-compose up -d