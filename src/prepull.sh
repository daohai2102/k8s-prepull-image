#!/bin/sh

set -euo pipefail

AWS_REGION=${AWS_REGION:-'us-east-1'}
AwS_DEFAULT_REGION=${AWS_REGION}
SLEEP_SECONDS=${SLEEP_SECONDS:-10}

while true; do
	echo "Getting the image list..."
  images_list=$(kubectl get deployment --all-namespaces -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | sort | uniq)
  echo Image list:
  echo "$images_list"
	echo "Getting all used ECR repositories..."
  ecr_repos=$(echo "$images_list" | grep amazonaws.com | cut -d'/' -f1 | uniq)
  echo ECR repositories:
  echo "$ecr_repos"
	echo "Logging in to all of the ECR repositories..."
  for repo in $ecr_repos; do
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $repo
  done
	image_pulled=0
	echo "Checking for new images..."
  for img in $images_list; do
    if ! docker image inspect $img >/dev/null 2>&1; then
      docker pull $img
      image_pulled=$((image_pulled+1))
    fi
  done
	echo "$image_pulled images pulled"
  sleep $SLEEP_SECONDS
done
