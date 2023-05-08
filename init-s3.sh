#!/bin/bash

# Create a small text file
echo "Hello, world!" > myfile.txt

# Create an S3 bucket
aws s3api create-bucket --bucket bucket-for-leagrnin --region us-west-2

# Upload file to S3 bucket
aws s3 cp myfile.txt s3://bucket-for-leagrnin/