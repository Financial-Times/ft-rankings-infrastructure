#!/usr/bin/env bash
#
# Push Docker image to ECR
#
# Script is intended to be run by CircleCI. It references variables CIRCLE_PROJECT_REPONAME and  IMAGE_VERSION
# unless passed in as command line parameter
#
#
# USAGE: ./push.sh [image_name] [image_version] [aws_account_id] [aws_region]
#   OR
# USAGE: ./push.sh --image_name=image_name --image_version=image_version [--aws_account_id=aws_account_id] [--aws_region=aws_region] [--ecr_endpoint=ecr-endpoint]

source $(dirname $0)/common.sh || echo "$0: Failed to source common.sh"

processCliArgs $@

usage() {
  echo "USAGE: $0 --image_name=image_name --image_version=image_version [--aws_account_id=aws_account_id] [--aws_region=aws_region] [--ecr_endpoint=ecr-endpoint]"
  exit 0
}

test -z ${ARGS[--image_name]} && ARGS[--image_name]=${1:-${CIRCLE_PROJECT_REPONAME}}
test -z ${ARGS[--image_version]} && ARGS[--image_version]=${2:-${CIRCLE_BUILD_NUM}}
test -z ${ARGS[--aws_account_id]} && ARGS[--aws_account_id]=${3:-"307921801440"}
test -z ${ARGS[--aws_region]} && ARGS[--aws_region]=${4:-"eu-west-1"}
test -z ${ARGS[--ecr_endpoint]} && ARGS[--ecr_endpoint]="${ARGS[--aws_account_id]}.dkr.ecr.${ARGS[--aws_region]}.amazonaws.com"

install_aws_cli() {
  pip install --upgrade pip
  pip install --upgrade awscli
}

test -z ${ARGS[--image_name]} && usage
test -z ${ARGS[--image_version]} && usage


# Check whether to install aws clis
which aws &>/dev/null || install_aws_cli

echo "Set AWS region"
aws configure set default.region ${ARGS[--aws_region]}

echo "Login to ECR"
$(aws ecr get-login --no-include-email)

echo "Verify repository exists"
aws ecr describe-repositories --repository-names ${ARGS[--image_name]}} &>/dev/null || \
aws ecr create-repository --repository-name ${ARGS[--image_name]}

echo "Tag image"
docker tag ${ARGS[--image_name]}:${ARGS[--image_version]} \
  ${ARGS[--ecr_endpoint]}/${ARGS[--image_name]}:${ARGS[--image_version]}
docker tag ${ARGS[--ecr_endpoint]}/${ARGS[--image_name]}:${ARGS[--image_version]} \
  ${ARGS[--ecr_endpoint]}/${ARGS[--image_name]}:latest

echo "Pushing container to ECR"
docker push ${ARGS[--ecr_endpoint]}/${ARGS[--image_name]}
