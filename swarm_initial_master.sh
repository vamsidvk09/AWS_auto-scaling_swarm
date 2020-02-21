#/bin/sh
# import any necessary scripts in the background
mkdir ./scripts
aws s3 cp s3://$S3_PATH/$ENVIRONMENT-crontab.txt /crontab.txt
aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ ./scripts/ --include "*" --recursive
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.env ./scripts/stacks/
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.yml ./scripts/stacks/
# aws s3 cp s3://$S3_PATH/$ENVIRONMENT/ap.sh ./scripts/
aws s3 cp s3://$S3_PATH/update_tokens.sh /update_tokens.sh
aws s3 cp s3://$S3_PATH/add_zone_label.sh /add_zone_label.sh

# echo "set timezone to America/Chicago"
unlink /etc/localtime
ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# echo "Create attachable internal network for the swarm"
docker network create --driver=overlay --attachable app-net

# cloudstor plugin allows persistent volumes on AWS and Azure but not on the new nvme backed instances
# https://docs.docker.com/docker-for-aws/persistent-data-volumes/
# another alternative https://rexray.readthedocs.io/en/stable/
# another current paid alternative https://docs.portworx.com/install-with-other/docker/swarm/
# Use this command if you want to support EBS as well as EFS
#docker plugin install --alias cloudstor:aws --grantall-permissions docker4x/cloudstor:18.03.0-ce-aws1 CLOUD_PLATFORM=AWS EFS_ID_REGULAR=<YOUR_EFS_ID> EFS_ID_MAXIO=<YOUR_MAXIO_EFS_ID> AWS_REGION=<REGION_NAME EFS_SUPPORTED=1 DEBUG=1
# Use this command if you only want to support EBS
# docker plugin install --alias cloudstor:aws --grant-all-permissions docker4x/cloudstor:18.03.0-ce-aws1 CLOUD_PLATFORM=AWS AWS_REGION=$AWS_DEFAULT_REGION EFS_SUPPORTED=0 DEBUG=1

# echo "set crontab and restart cron/rsyslog to catch new TZ above"
crontab /crontab.txt
# reset cron to use updated timezone
service crond restart
service rsyslog restart

# echo "Run docker deploy scripts"
cd ./scripts
shopt -s extglob nullglob
for file in *; do
    chmod +x $file
    . $file
done
