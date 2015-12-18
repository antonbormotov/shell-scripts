#!/bin/sh
#===================================================================================
#
# FILE: create-cloudwatch-alarms.sh
#
# USAGE: create-cloudwatch-alarms.sh <IP-ADDRESS> [ --force  | --dry-run ]
#
# DESCRIPTION: Script creates 2 alarms for instance with PRIMARY_PUBLIC_IP_ADDRESS
# It does follow steps:
# 1. Creates high cpu usage alarm
# 2. Creates instance statusCheck alarm
#
#===================================================================================
PRIMARY_PUBLIC_IP_ADDRESS="$1"
echo "${PRIMARY_PUBLIC_IP_ADDRESS}" | grep -q -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
if [ $? -ne 0 ]
then
    echo "### Usage: $0 <IP-ADDRESS>"
    echo "### IP address have to be presented in format X.X.X.X"
    exit 1
fi

if [ "$2" != "--force" ] && [ "$2" != "--dry-run" ]
then
    echo "### Usage: $0 $1 [ --force  | --dry-run ]"
    exit 1
fi

if [ "$1" = "--dry-run" ]
then
    DRYRUN="--dry-run"
else
    DRYRUN=""
fi

# Trying auto-detect AWS region
AWS_DEFAULT_REGION=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/placement/availability-zone | sed -e 's/\([1-9]\).$/\1/g')

# Export environment variables for awscli
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-1}"
export AWS_DEFAULT_OUTPUT="text"

# 1) Get id and tag Name of instance
INSTANCE_NAME=$(aws ec2 describe-instances --filters "Name=ip-address ,Values=${PRIMARY_PUBLIC_IP_ADDRESS}" --query 'Reservations[0].Instances[0].[Tags[?Key==`Name`].Value]')

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=ip-address ,Values=${PRIMARY_PUBLIC_IP_ADDRESS}" --query 'Reservations[0].Instances[0].InstanceId]')

if [ "${INSTANCE_NAME}" = "None" ] 
then
    echo "### Could not find instance with IP ${PRIMARY_PUBLIC_IP_ADDRESS}"
    exit 1
fi

# 2) Create statusCheck metric
aws cloudwatch put-metric-alarm --alarm-name cpu-mon --alarm-description "Alarm when CPU exceeds 70 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=i-12345678 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent
