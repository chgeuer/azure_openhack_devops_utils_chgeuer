#!/bin/bash

ohteamvalues="$(cat ./ohteamvalues)"

declare -A charts=(
   ["api-poi"]="apis/poi/charts/mydrive-poi"
   ["api-trip"]="apis/trips/charts/mydrive-trips"
   ["api-user-java"]="apis/user-java/charts/mydrive-user-java"
   ["api-user"]="apis/userprofile/charts/mydrive-user"
)

# for chartName in "${!charts[@]}"; do echo "${chart} lives in ${charts["${chartName}"]}" ; done

chartName="api-poi"
chartDir="${charts[$chartName]}"

endpoint="$( echo "${ohteamvalues}" | egrep "^endpoint" | awk '{print $2}' )"
acr="$( echo "${ohteamvalues}" | egrep "^ACR$(printf '\t')" | awk '{print $2}' )"
image="${acr}.azurecr.io/devopsoh/${chartName}"

helm delete --purge "${chartName}"
helm install "${chartDir}" --name "${chartName}" --set "repository.image=${image},env.webServerBaseUri=http://${endpoint},ingress.rules.endpoint.host=${endpoint}"
