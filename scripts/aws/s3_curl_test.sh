#!/bin/bash

# -----------------------------------------------------------------------------
# s3-test.sh
#
# Purpose:
#   - Test access to an Amazon S3 bucket object using raw HTTP requests and
#     AWS Signature Version 4.
#   - Does NOT require AWS CLI or SDK.
#
# Usage:
#   ./s3-test.sh <AWS_ACCESS_KEY> <AWS_SECRET_KEY> <BUCKET_NAME> <OBJECT_NAME>
#
# Notes:
#   - AWS credentials are passed as arguments, not stored in the script.
#   - Be aware that command-line arguments may be visible to other users.
#   - Region defaults to us-east-1; update as needed for your bucket.
# -----------------------------------------------------------------------------

# Ensure correct number of arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <AWS_ACCESS_KEY> <AWS_SECRET_KEY> <BUCKET_NAME> <OBJECT_NAME>"
    exit 1
fi

# -----------------------------------------------------------------------------
# Input Parameters
# -----------------------------------------------------------------------------
AWS_ACCESS_KEY=$1      # Your AWS access key ID
AWS_SECRET_KEY=$2      # Your AWS secret access key
BUCKET_NAME=$3         # Name of the S3 bucket
OBJECT_NAME=$4         # Object/key to GET from the bucket
REGION="us-east-1"     # AWS region of the bucket (modify if needed)

# -----------------------------------------------------------------------------
# Prepare variables for AWS Signature V4
# -----------------------------------------------------------------------------
HOST="$BUCKET_NAME.s3.amazonaws.com"           # S3 endpoint
DATE=$(date -u +"%Y%m%dT%H%M%SZ")             # Timestamp in ISO8601 basic format
SHORT_DATE=$(date -u +"%Y%m%d")               # Date for credential scope
SERVICE="s3"                                  # AWS service name
SIGNED_HEADERS="host;x-amz-date"              # Headers included in signature

# Construct canonical request (per AWS Signature V4 spec)
CANONICAL_REQUEST="GET\n/$OBJECT_NAME\n\nhost:$HOST\nx-amz-date:$DATE\n\n$SIGNED_HEADERS\nUNSIGNED-PAYLOAD"

# SHA256 hash of the canonical request
HASHED_CANONICAL_REQUEST=$(echo -n "$CANONICAL_REQUEST" | openssl dgst -sha256)

# -----------------------------------------------------------------------------
# Create the string to sign
# -----------------------------------------------------------------------------
STRING_TO_SIGN="AWS4-HMAC-SHA256\n$DATE\n$SHORT_DATE/$REGION/$SERVICE/aws4_request\n$HASHED_CANONICAL_REQUEST"

# -----------------------------------------------------------------------------
# Derive the signing key
# -----------------------------------------------------------------------------
# Stepwise HMAC-SHA256 derivation per AWS documentation
KDATE=$(echo -n "$SHORT_DATE" | openssl dgst -sha256 -hmac "AWS4$AWS_SECRET_KEY" | sed 's/^.* //')
KREGION=$(echo -n "$REGION" | openssl dgst -sha256 -hmac "$KDATE" | sed 's/^.* //')
KSERVICE=$(echo -n "$SERVICE" | openssl dgst -sha256 -hmac "$KREGION" | sed 's/^.* //')
KREQUEST=$(echo -n "aws4_request" | openssl dgst -sha256 -hmac "$KSERVICE" | sed 's/^.* //')

SIGNING_KEY="$KREQUEST"   # Final signing key

# -----------------------------------------------------------------------------
# Generate the request signature
# -----------------------------------------------------------------------------
SIGNATURE=$(echo -n "$STRING_TO_SIGN" | openssl dgst -sha256 -hmac "$SIGNING_KEY" | sed 's/^.* //')

# -----------------------------------------------------------------------------
# Perform the GET request
# -----------------------------------------------------------------------------
curl -X GET "https://$HOST/$OBJECT_NAME" \
     -H "Authorization: AWS4-HMAC-SHA256 Credential=$AWS_ACCESS_KEY/$SHORT_DATE/$REGION/$SERVICE/aws4_request, SignedHeaders=$SIGNED_HEADERS, Signature=$SIGNATURE" \
     -H "x-amz-date: $DATE"

# -----------------------------------------------------------------------------
# End of Script
# -----------------------------------------------------------------------------
