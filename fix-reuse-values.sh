#!/bin/bash

#
# The ohteamvalues file from the ZIP file
#
ohteamvalues="$(cat ./ohteamvalues)"

#
# The directory where https://github.com/Azure-Samples/openhack-devops-team/ is checked-out to
#
sourceDir="."

declare -A charts=(
   ["api-poi"]="apis/poi/charts/mydrive-poi"
   ["api-trip"]="apis/trips/charts/mydrive-trips"
   ["api-user-java"]="apis/user-java/charts/mydrive-user-java"
   ["api-user"]="apis/userprofile/charts/mydrive-user"
)

for chartName in "${!charts[@]}"; do
   chartDir="${charts[$chartName]}"

   endpoint="$( echo "${ohteamvalues}" | egrep "^endpoint" | awk '{print $2}' )"
   acr="$( echo "${ohteamvalues}" | egrep "^ACR$(printf '\t')" | awk '{print $2}' )"
   image="${acr}.azurecr.io/devopsoh/${chartName}"

   echo "Deleting old chart ${chartName}"
   helm delete --purge "${chartName}"

   echo "Installing clean version of ${chartName}"
   helm install "${chartDir}" --name "${chartName}" \
       --set "repository.image=${image}" \
       --set "env.webServerBaseUri=http://${endpoint}" \
       --set "ingress.rules.endpoint.host=${endpoint}"
done
