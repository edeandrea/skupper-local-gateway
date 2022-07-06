#!/bin/bash -e

if [ $# -lt 2 ]; then
  echo "Invalid number of arguments"
  echo "Usage: generateBundle.sh <project_name> <laptop_file_name>"
  exit 1
fi

PROJECT_NAME=$1
LAPTOP_FILE_NAME=$2

if [ ! -f "${LAPTOP_FILE_NAME}.yaml" ]; then
  echo "${LAPTOP_FILE_NAME}.yaml does not exist!"
  exit 1
fi

oc project $PROJECT_NAME
skupper init
rm -rf bundle/$LAPTOP_FILE_NAME
mkdir -p bundle/$LAPTOP_FILE_NAME
cp captureports.py bundle/$LAPTOP_FILE_NAME
skupper gateway generate-bundle ${LAPTOP_FILE_NAME}.yaml bundle/$LAPTOP_FILE_NAME
cd bundle/$LAPTOP_FILE_NAME
gzip -dc ${LAPTOP_FILE_NAME}.tar.gz | tar xvf -
chmod +x *.sh