#!/bin/bash

NUM_CONTAINERS=1
CONTAINER_PREFIX=zgc_dev_

docker volume create projects
docker volume create dump

# generate devcontainer.json
for ((i=1; i<=NUM_CONTAINERS; i++)); do

    CONTAINER_NAME="container-$i"
    SERVICE_NAME="$CONTAINER_PREFIX$i"
    WORKSPACE_FOLDER="container$i"

    mkdir -p $WORKSPACE_FOLDER

    sed -e "s/\${CONTAINER_NAME}/${CONTAINER_NAME}/g"\
        -e "s/\${SERVICE_NAME}/${SERVICE_NAME}/g"\
        -e "s/\${WORKSPACE_FOLDER}/${WORKSPACE_FOLDER}/g"\
        templates/devcontainer.json > ${WORKSPACE_FOLDER}/.devcontainer.json
done

# generate docker-compose.yml
cat templates/docker-compose.yml > docker-compose.yml
SERVICE_CONTENT=""
for ((i=1; i<=NUM_CONTAINERS; i++)); do
    SERVICE_NAME="$CONTAINER_PREFIX$i"

    sed  -e "s/\${SERVICE_NAME}/${SERVICE_NAME}/g" templates/service.yml >> docker-compose.yml
done
