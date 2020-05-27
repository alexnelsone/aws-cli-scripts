#!/bin/bash

ENVIRONMENT=`cat /etc/IDENTIFIER-environment`
TYPE=`cat /etc/IDENTIFIER-application | cut -d '-' -f 1`
COLOR=`cat /etc/IDENTIFIER-color`
INSTANCE_TYPE=r5n.xlarge

VAL=$ENVIRONMENT-IDENTIFIER-$TYPE
printf "Creating image of $TYPE servers in $ENVIRONMENT\n"

#DATE=$(date '+%Y%m%d-%H%M%S')

# describe instances
#OUTPUT=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$VAL*" "Name=instance-state-name,Values=running" --region us-east-1 --query 'Reservations[*].Instances[*].{Instance:InstanceId}' --output text`
OUTPUT=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
for instanceID in $OUTPUT
do
  DATE=$(date '+%Y%m%d-%H%M%S')

  imageID=`aws ec2 create-image --description IDENTIFIER-$ENVIRONMENT-$TYPE-$COLOR-$DATE --name IDENTIFIER-$ENVIRONMENT-$TYPE-$COLOR-$DATE --no-reboot --instance-id $instanceID --region us-east-1 --output text`
  aws ec2 create-tags --resources $imageID --tags Key=Name,Value=IDENTIFIER-$ENVIRONMENT-$TYPE-$COLOR-$DATE --region us-east-1

  printf "created image $imageID for instance-id $instanceID with name IDENTIFIER-$ENVIRONMENT-$TYPE-$DATE\n"

  launchConfigName=IDENTIFIER-$ENVIRONMENT-$TYPE-$COLOR-webServerLaunchConfig-$DATE

  aws autoscaling create-launch-configuration --launch-configuration-name $launchConfigName --image-id $imageID --region us-east-1 --instance-id $instanceID --output text --instance-type $INSTANCE_TYPE --user-data file://userdata.txt

  printf "this is the launchConfig: $launchConfigName\n"

  # shellcheck disable=SC1073
  #autoScalingGroup=`aws autoscaling describe-auto-scaling-groups --region us-east-1 --query 'AutoScalingGroups[*].Tags[*].{Name:Key,Value:ResourceId}[0]' --output text | grep $ENVIRONMENT | grep $TYPE | grep $COLOR | awk '{print $2}'`
  autoScalingGroup=IDENTIFIER-qa-stack-learnerTool-1-webServerGroup-CG884VG3O283

  if [ -z "$autoScalingGroup"]
  then
  autoScalingGroup=`aws autoscaling describe-auto-scaling-groups --region us-east-1 --query 'AutoScalingGroups[*].Tags[*].{Name:Key,Value:ResourceId}[0]' --output text | grep $ENVIRONMENT | grep $TYPE | awk '{print $2}'`
  autoScalingGroup=`echo $autoScalingGroup | cut -d ' ' -f 1`
  fi

  printf "this is the autoScalingGroup: $autoScalingGroup \n"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name $autoScalingGroup --launch-configuration-name $launchConfigName --region us-east-1 --output text
  aws autoscaling create-or-update-tags --tags ResourceId=$autoScalingGroup,ResourceType=auto-scaling-group,Key=color,Value=$COLOR,PropagateAtLaunch=true --region us-east-1
  # --tags Key=env,Value=prod,PropagateAtLaunch=true

done