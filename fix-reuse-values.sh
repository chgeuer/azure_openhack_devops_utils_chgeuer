#!/bin/bash

# -v The ohteamvalues file from the ZIP file
# -r The directory where https://github.com/Azure-Samples/openhack-devops-team/ is checked-out to

if [ $# -ne 2 ]; then 
   echo "Need to specify path to values file and path to sources"
   exit 1
fi

VALUEFILE=$1
REPO=$2


echo "Using values from file \"${VALUEFILE}\""
echo "Using repo in directory  \"${REPO}\""


# while getopts v:r: option
# do
# case "${option}"
# in
# v) VALUEFILE=${OPTARG};;
# r) REPO=${OPTARG};;
# esac
# done

ohteamvalues="$( cat "${VALUEFILE}" )"

declare -A charts=(
   ["api-poi"]="apis/poi/charts/mydrive-poi"
   ["api-trip"]="apis/trips/charts/mydrive-trips"
   ["api-user-java"]="apis/user-java/charts/mydrive-user-java"
   ["api-user"]="apis/userprofile/charts/mydrive-user"
)

echo "Cleaning Helm deployment for team \"$( echo "${ohteamvalues}" | egrep "^teamNumber$(printf '\t')" | awk '{print $2}' )\""

for chartName in "${!charts[@]}"; do
   chartDir="${charts[$chartName]}"

   endpoint="$( echo "${ohteamvalues}" | egrep "^endpoint$(printf '\t')" | awk '{print $2}' )"
   acr="$( echo "${ohteamvalues}" | egrep "^ACR$(printf '\t')" | awk '{print $2}' )"
   image="${acr}.azurecr.io/devopsoh/${chartName}"

   echo "Deleting old chart ${chartName}"
   helm delete --purge "${chartName}"

   echo "Installing clean version of ${chartName}"
   helm install "${REPO}/${chartDir}" --name "${chartName}" \
       --set "repository.image=${image}" \
       --set "env.webServerBaseUri=http://${endpoint}" \
       --set "ingress.rules.endpoint.host=${endpoint}"
done
