#!/usr/bin/env bash

GOOGLE_CLOUD_PROJECT_ID="my-project-id"
GCP_DEPLOY_AS_USER="your-email@example.com"
SERVICES_TO_CLEAN="default"

##
## Shouldn't have to touch below.
##
START_GCP_USER=$(gcloud config get-value account)

DIRECTORY=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${DIRECTORY}" || exit

if [ "${START_GCP_USER}" != "${GCP_DEPLOY_AS_USER}" ]; then
  echo "----"
  echo "Setting gcloud deploy user..."
  gcloud config set account "${GCP_DEPLOY_AS_USER}"
fi

echo "----"
echo "Starting deployment..."
gcloud app deploy --project="${GOOGLE_CLOUD_PROJECT_ID}" ./ -q

echo "----"
echo "Deployment complete. Sleeping for 10 seconds before cleanup..."
sleep 10

function delete_versions() {
    ###
    #  delete_versions "my-project-id" "my-service"
    ###
    GCP_PROJECT="${1}"
    GCP_SERVICE="${2}"
    DELETE_VERSIONS=""
    echo "  Requesting versions for GCP project: ${GCP_PROJECT}"
    echo "                      Project service: ${GCP_SERVICE}"
    VERSIONS=$(gcloud app versions list --service="${GCP_SERVICE}" --project="${GCP_PROJECT}" --sort-by '~version' --format 'csv[no-heading,no-heading](version.id, traffic_split)')
    DELETE_COUNT=0
    KEEP_COUNT=0
    for VERSION in ${VERSIONS}
    do
        IFS=',' read -ra INFO <<< "${VERSION}"
        if [ "${INFO[1]}" != "0.00" ]
        then
          ((KEEP_COUNT++))
          echo "Keeping the following versions:"
          echo " - ${GCP_PROJECT}/${GCP_SERVICE}/${INFO[0]}"
        else
          ((DELETE_COUNT++))
          DELETE_VERSIONS="${DELETE_VERSIONS} ${INFO[0]}"
        fi
    done
    if [ "${DELETE_VERSIONS}" != "" ]; then
      echo "${DELETE_VERSIONS}"
      # shellcheck disable=SC2086
      DELETE_COMMAND="gcloud app versions delete --service=${GCP_SERVICE} --project=${GCP_PROJECT}"
      for SCHEDULED in ${DELETE_VERSIONS}
      do
        DELETE_COMMAND="${DELETE_COMMAND} ${SCHEDULED}"
      done
      DELETE_COMMAND="${DELETE_COMMAND} -q"
      # gcloud app versions delete --service=default --project=my-project-id version1 version2 -q
      $DELETE_COMMAND
    fi

    echo "----"
    echo "Found..."
    echo "  * ${KEEP_COUNT} version(s) to keep"
    echo "  * ${DELETE_COUNT} version(s) to delete"
}

echo "----"
echo "Cleaning up old versions..."
for CLEANUP_SERVICE in ${SERVICES_TO_CLEAN}
do
  delete_versions "${GOOGLE_CLOUD_PROJECT_ID}" "${CLEANUP_SERVICE}"
done

echo "----"
echo "Cleanup complete..."

echo "----"
echo "Finished."
exit 0
