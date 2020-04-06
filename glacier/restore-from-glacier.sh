#!/bin/bash

# TODO: add bulk restore option

# HOW TO USE THIS SCRIPT
# Replace the root_bucket variable with the bucket name
# Replace the S3prefix variable below with the prefix for the files you want to restore
# You do not need the beginning / on the S3Prefix or any / on the root_bucket

# root_bucket should be set to the bucket that contains the object you want to modify the storage class of.
root_bucket=$1
S3prefix=$2
tmp_file="/var/tmp/restore_from_glacier"
profile=$3

printf "collecting files to change class\n"
aws s3api list-objects-v2 --bucket $root_bucket  --prefix emr-appdata --prefix $S3prefix --query "Contents[?StorageClass=='GLACIER']" --output text --profile $profile  | awk '{print $2}' > $tmp_file

