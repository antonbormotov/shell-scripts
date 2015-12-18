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

if [ "$(curl --fail --connect-timeout 2 http://169.254.169.254/latest/meta-data/iam/security-credentials/> /dev/null 2>&1 ; echo $?)" -ne 0 ]
then
    echo "### Role is not assigned to the instance or it is not aws instance"
    # Look for .aws/config and credential files in home directory
    if [ ! -f "${HOME}/.aws/config" ] && [ ! -f "${HOME}/.aws/credentials" ] 
    then
        echo "### AWS cli has not been configured yet."
        echo "### To configure aws cli tool, please, run: aws configure"
        exit 1
    fi
fi

# 1) Get instance id and name tag
INSTANCE_NAME=$(aws ec2 describe-instances --filters "Name=ip-address ,Values=${PRIMARY_PUBLIC_IP_ADDRESS}" --query 'Reservations[0].Instances[0].[Tags[?Key==`Name`].Value]')

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=ip-address ,Values=${PRIMARY_PUBLIC_IP_ADDRESS}" --query 'Reservations[0].Instances[0].InstanceId')

if [ "${INSTANCE_NAME}" = "None" ] 
then
    echo "### Could not find instance with IP ${PRIMARY_PUBLIC_IP_ADDRESS}"
    exit 1
fi

# 2) Create high CPU usage metric
ARN_OF_SNS_TOPIC="arn:aws:sns:ap-southeast-1:976402106354:iprice-alarm"
CPU_USAGE=50

aws cloudwatch put-metric-alarm ${DRYRUN}\
    --alarm-name "${INSTANCE_NAME}-cpu"\
    --alarm-description "Alarm when CPU exceeds ${CPU_USAGE}%"\
    --actions-enabled\
    --ok-actions "${ARN_OF_SNS_TOPIC}"\
    --alarm-actions "${ARN_OF_SNS_TOPIC}"\
    --insufficient-data-actions "${ARN_OF_SNS_TOPIC}"\
    --metric-name CPUUtilization\
    --namespace AWS/EC2\
    --statistic Average\
    --dimensions  Name=InstanceId,Value=${INSTANCE_ID}\
    --period 300\
    --threshold ${CPU_USAGE}\
    --comparison-operator GreaterThanThreshold\
    --evaluation-periods 1\
    --unit Percent

# 3) Create status check metric
aws cloudwatch put-metric-alarm ${DRYRUN}\
    --alarm-name "${INSTANCE_NAME}-status"\
    --alarm-description "Alarm when statusCheck failed"\
    --actions-enabled\
    --ok-actions "${ARN_OF_SNS_TOPIC}"\
    --alarm-actions "${ARN_OF_SNS_TOPIC}"\
    --insufficient-data-actions "${ARN_OF_SNS_TOPIC}"\
    --metric-name StatusCheckFailed\
    --namespace AWS/EC2\
    --statistic Average\
    --dimensions  Name=InstanceId,Value=${INSTANCE_ID}\
    --period 300\
    --threshold 1\
    --comparison-operator GreaterThanOrEqualToThreshold\
    --evaluation-periods 1\
    --unit Percent