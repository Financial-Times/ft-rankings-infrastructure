#!/usr/bin/env bash
#
# Create ECS task defintion and update service
#
# Script is intended to be run by CircleCI. It references variables CIRCLE_PROJECT_REPONAME and  CIRCLE_BUILD_NUM
# unless passed in as command line parameter
#
# Script is based on https://github.com/circleci/go-ecs-ecr/blob/master/deploy.sh
#
# USAGE: deploy.sh <ecs_cluster> <ecs_service> [image_name] [image_version] [aws_account_id] [region]
#   OR
# USAGE: deploy.sh --ecs_cluster=cluster_name --ecs_service=service_name [--image_name=image_name] [--image_version=image_version] [--aws_account_id=aws_account_id] [--aws_region=aws_region]
#

source $(dirname $0)/common.sh || echo "$0: Failed to source common.sh"
processCliArgs $@

test -z ${ARGS[--ecs_cluster]} && ARGS[--ecs_cluster]=$1
test -z ${ARGS[--ecs_service]} && ARGS[--ecs_service]=$2
test -z ${ARGS[--image_name]} && ARGS[--image_name]=${CIRCLE_PROJECT_REPONAME}
test -z ${ARGS[--image_version]} && ARGS[--image_version]=${CIRCLE_BUILD_NUM}
test -z ${ARGS[--aws_account_id]} && ARGS[--aws_account_id]="307921801440"
test -z ${ARGS[--aws_region]} && ARGS[--aws_region]="eu-west-1"
test -z ${ARGS[--splunk_index]} && ARGS[--splunk_index]="rankings"
test -z ${ARGS[--splunk_source]} && ARGS[--splunk_source]="rankings"
test -z ${ARGS[--memory]} && ARGS[--memory]="512"
test -z ${ARGS[--memory_reservation]} && ARGS[--memory_reservation]="256"
test -z ${ARGS[--cpu]} && ARGS[--cpu]="512"

deploy() {
    if [[ $(aws ecs update-service --cluster ${ARGS[--ecs_cluster]} --service ${ARGS[--ecs_service]} --task-definition $revision \
            --output text --query 'service.taskDefinition') != $revision ]]; then
        echo "Error updating service."
        return 1
    fi
}

make_task_definition(){
	task_template='[
		{
			"name": "%s",
			"image": "%s.dkr.ecr.%s.amazonaws.com/%s:%s",
			"essential": true,
  			"memory": %s,
  			"memoryReservation": %s,
  			"cpu": %s,
			"portMappings": [
				{
					"containerPort": 80
				}
			],
			"mountPoints": [
          		{
					"sourceVolume": "sysconfig",
					"containerPath": "/etc/sysconfig",
					"readOnly": true
				}
			]
		}
	]'

	task_def=$(printf "$task_template" 	${ARGS[--ecs_service]} \
										${ARGS[--aws_account_id]} \
										${ARGS[--aws_region]} \
										${ARGS[--image_name]} \
										${ARGS[--image_version]} \
										${ARGS[--memory]} \
                      					${ARGS[--memory_reservation]} \
                      					${ARGS[--cpu]} )
}

make_task_definition_with_splunk(){
	task_template='[
		{
			"name": "%s",
			"image": "%s.dkr.ecr.%s.amazonaws.com/%s:%s",
			"essential": true,
  			"memory": %s,
  			"memoryReservation": %s,
  			"cpu": %s,
			"portMappings": [
				{
					"containerPort": 80
				}
			],
			"mountPoints": [
          		{
					"sourceVolume": "sysconfig",
					"containerPath": "/etc/sysconfig",
					"readOnly": true
				}
			],
			"logConfiguration": {
				"logDriver": "splunk",
				"options": {
					"splunk-url": "https://http-inputs-financialtimes.splunkcloud.com",
					"splunk-token": "%s",
					"splunk-index": "%s",
					"splunk-source": "%s",
					"splunk-insecureskipverify": "true",
					"splunk-format": "raw"
				}
			}
		}
	]'

	task_def=$(printf "$task_template" 	${ARGS[--ecs_service]} \
										${ARGS[--aws_account_id]} \
										${ARGS[--aws_region]} \
										${ARGS[--image_name]} \
										${ARGS[--image_version]} \
										${ARGS[--memory]} \
                      					${ARGS[--memory_reservation]} \
                      					${ARGS[--cpu]} \
										${ARGS[--splunk_key]} \
										${ARGS[--splunk_index]} \
										${ARGS[--splunk_source]} )
}

make_volume_definition() {
  volume_template='[
	{
		"name": "sysconfig",
		"host": {
		"sourcePath": "/opt/rankings"
		}
	}
  ]'
  volume=$(printf "$volume_template")
}

register_task_definition() {
    #echo "Registering task definition ${task_def}"
	echo "Registering task definition"
    if revision=$(aws ecs register-task-definition --container-definitions "$task_def" --volumes "${volume}" --family "${ARGS[--ecs_service]}" --output text --query 'taskDefinition.taskDefinitionArn'); then
        echo "Revision: $revision"
    else
        echo "Failed to register task definition"
        return 1
    fi

}

#printCliArgs
#exit 0
if [[ -z ${ARGS[--splunk_key]} ]]; then
	make_task_definition
else
	make_task_definition_with_splunk
fi
make_volume_definition
register_task_definition

deploy
