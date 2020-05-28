#!/bin/bash
bucket=$1
region=$2
now=$(date +%s)
aws cloudwatch get-metric-statistics --namespace AWS/S3 --start-time "$(echo "$now - 86400" | bc)" --end-time "$now" --period 86400 --statistics Average --region $region --metric-name BucketSizeBytes --dimensions Name=BucketName,Value="$bucket" Name=StorageType,Value=StandardStorage
