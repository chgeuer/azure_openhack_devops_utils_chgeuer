#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl'
slot1="blue" slot2="green" apis=( "api-poi" "api-trip" "api-user" "api-user-java" )
function getHelmData { helm get values --all "$1" | yq . ; }
function getJsonVal { echo $(echo "$1" | jq -r "$2") ; }
function prodSlot { echo $(getJsonVal "$1" ".productionSlot") ; }
function status { echo $(getJsonVal "$1" ".$2.enabled" | sed 's/true/enabled/g' | sed 's/false/disabled/g') ; }
function tag { echo $(getJsonVal "$1" ".$2.tag") ; }
function healthHost { echo "$(getJsonVal "$1" .ingress.rules.endpoint.host)" ; }
function healthPath { echo "$(getJsonVal "$1" ".ingress.rules.endpoint.paths[] | select(.path | contains(\"healthcheck\")) | .path")" ; }
function healthURL { echo "$(healthHost "$1")$(healthPath "$1")" ; }
function http_status { echo $(curl --silent --output /dev/null --write-out '%{http_code}' $1) ; }
function displayProd { if [ $1 == $2 ]; then echo "Production"; else echo "Staging"; fi ; }
function displayHealth { if [ $1 == $2 ]; then echo "health=$3"; else echo "health=$4"; fi ; }
for api in "${apis[@]}"; do
  json=$(getHelmData ${api}) productionSlot=$(prodSlot "${json}") healthProd=$(http_status "http://$(healthURL "${json}")") healthStaging=$(http_status "http://stage$(healthURL "${json}")")
  echo "${api}
    ${slot1} $(displayProd "${slot1}" "${productionSlot}") $(status "${json}" "${slot1}") tag=$(tag "${json}" "${slot1}") $(displayHealth "${slot1}" "${productionSlot}" "${healthProd}" "${healthStaging}")
    ${slot2} $(displayProd "${slot2}" "${productionSlot}") $(status "${json}" "${slot2}") tag=$(tag "${json}" "${slot2}") $(displayHealth "${slot2}" "${productionSlot}" "${healthProd}" "${healthStaging}")"
done
