#!/usr/bin/env bash
#
# Look up ECS_CLUSTER name /etc/ecs/ecs.config
# Find secrets id from SERCRETS_MAP using ECS_CLUSTER name 
# Update credentials if found
#
# USAGE: ./secretsreader.sh 
#        To schedule execution from cron every 5 minutes
#           */5 * * * * /opt/rankings/secretsreader.sh
# 

info() {
  logger ${1}
  echo -e "\e[34mINFO: ${1}\e[0m"
}

error() {
  logger ${1}
  echo -e "\e[31mERROR: $1\e[0m"
  ERROR=$2
}

errorAndExit() {
  logger ${1}
  echo -e "\e[31mERROR: $1\e[0m"
  exit $2
}

declare -A SERCRETS_MAP
SERCRETS_MAP[dev-ft-rankings]="rankings-dev-rds"
SERCRETS_MAP[rankings-prod]="rankings-prod-rds"
SRC_DIR="/tmp"
DST_DIR="/opt/rankings"
ECS_CLUSTER=$(grep ECS_CLUSTER /etc/ecs/ecs.config | cut -d '=' -f 2)

test -z ${ECS_CLUSTER} && errorAndExit "Failed to find ECS_CLUSTER name" 1
test -z ${SERCRETS_MAP[${ECS_CLUSTER}]} && errorAndExit "Failed to find secret-id from SECRETS_MAP" 1


echo -n $(aws secretsmanager get-secret-value --secret-id ${SERCRETS_MAP[${ECS_CLUSTER}]} --query SecretString | jq -r '.' | jq -r .username) > ${SRC_DIR}/mysql-app-user
echo -n $(aws secretsmanager get-secret-value --secret-id ${SERCRETS_MAP[${ECS_CLUSTER}]} --query SecretString | jq -r '.' | jq -r .password) > ${SRC_DIR}/mysql-app-password
echo -n $(aws secretsmanager get-secret-value --secret-id ${SERCRETS_MAP[${ECS_CLUSTER}]} --query SecretString | jq -r '.' | jq -r .host) > ${SRC_DIR}/mysql-app-host
echo -n $(aws secretsmanager get-secret-value --secret-id ${SERCRETS_MAP[${ECS_CLUSTER}]} --query SecretString | jq -r '.' | jq -r .name) > ${SRC_DIR}/mysql-app-name

test -d ${DST_DIR} || mkdir -p ${DST_DIR}

for each in mysql-app-host mysql-app-name mysql-app-password mysql-app-user; do
    if [[ "$(wc -c < ${SRC_DIR}/${each})" -gt "0" ]]; then
        info "Updating secrets for ${each}"
        cat ${SRC_DIR}/${each} > ${DST_DIR}/${each}
    else
        error "Failed to find secret for ${each}"
    fi
done
