#!/bin/bash

# Bootstrap routine for ECS instance
#
# When script has been modified upload it https://s3-eu-west-1.amazonaws.com/cms-tech-s3/ECS-bootstrap/cms-ecs-bootstrap.sh

DST_DIR="/opt/rankings"

echo "Adding logging drivers to ECS config"
echo 'ECS_AVAILABLE_LOGGING_DRIVERS= ["json-file","awslogs","splunk"]' >> /etc/ecs/ecs.config
cat /etc/ecs/ecs.config
echo
stop ecs && start ecs

test -d ${DST_DIR} || mkdir -p ${DST_DIR}

curl --connect-timeout 3 -o ${DST_DIR}/secretsreader.sh -s https://raw.githubusercontent.com/Financial-Times/ft-rankings-infrastructure/master/lib/sh/secretsreader.sh
chmod 755 ${DST_DIR}/secretsreader.sh && ${DST_DIR}/secretsreader.sh
(crontab -l ; echo "*/5 * * * *  ${DST_DIR}/secretsreader.sh") | crontab -

# Loading the Crontab for Admin tasks

#updaterssfeed
(crontab -l; echo "*/10 * * * 1-5 docker run -it 307921801440.dkr.ecr.eu-west-1.amazonaws.com/ft-rankings-admin:194 bash -c 'cd lib/crn && source /etc/ft-profile.conf && php updaterssfeeds'") | crontab -

#applyscheduledtasks
(crontab -l; echo "*/10 * * * 1-5 docker run -it 307921801440.dkr.ecr.eu-west-1.amazonaws.com/ft-rankings-admin:194 bash -c 'cd lib/crn && source /etc/ft-profile.conf && php applyscheduledtasks'") | crontab -

#updatefxrates
(crontab -l; echo "*/10 * * * 1-5 docker run -it 307921801440.dkr.ecr.eu-west-1.amazonaws.com/ft-rankings-admin:194 bash -c 'cd lib/crn && source /etc/ft-profile.conf && php updatefxrates.php'") | crontab -

#updateicalfeeds
(crontab -l; echo "*/10 * * * 1-5 docker run -it 307921801440.dkr.ecr.eu-west-1.amazonaws.com/ft-rankings-admin:194 bash -c 'cd lib/crn && source /etc/ft-profile.conf && php updateicalfeeds'") | crontab -

