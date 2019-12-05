#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl', 'printf"
slots=( "blue" "green" ) apis=( "api-poi" "api-trip" "api-user" "api-user-java" ) format="%-15s %-5s %-10s %-6s %-12s %-8s %s"
declare -A helmValues
function downloadHelmData { helm get values --all "$1" | yq . ; }
for api in "${apis[@]}"; do
    helmValues["${api}"]="$(downloadHelmData "${api}")"
done
function getCachedHelmData { echo "${helmValues["$1"]}" ; }
function getJsonVal { echo $(echo "$1" | jq -r "$2") ; }
function prodSlot { echo $(getJsonVal "$1" ".productionSlot") ; }
function status { echo $(getJsonVal "$1" ".$2.enabled" | sed 's/true/enabled/g' | sed 's/false/disabled/g') ; }
function tag { echo $(getJsonVal "$1" ".$2.tag") ; }
function healthHost { echo "$(getJsonVal "$1" .ingress.rules.endpoint.host)" ; }
function healthPath { echo "$(getJsonVal "$1" ".ingress.rules.endpoint.paths[] | select(.path | contains(\"healthcheck\")) | .path")" ; }
function healthURL { echo "$(healthHost "$1")$(healthPath "$1")" ; }
function http_status { echo $(curl --silent --output /dev/null --write-out '%{http_code}' $1) ; }
function displayProd { if [ $1 == $2 ]; then echo "Production"; else echo "Staging"; fi ; }
function displayHealth { if [ $1 == $2 ]; then echo "$3"; else echo "$4"; fi ; }
function displayHeader { printf "${format}\n" "api" "slot" "role" "health" "status" "tag" ; }
function displaySlot {
    api="$1" slot="$2"
    json=$(getCachedHelmData ${api})
    productionSlot=$(prodSlot "${json}")
    healthProd=$(http_status "http://$(healthURL "${json}")")
    healthStaging=$(http_status "http://stage$(healthURL "${json}")")
    printf "${format}" "${api}" "${slot}" \
        "$(displayProd "${slot}" "${productionSlot}")" \
        "$(displayHealth "${slot}" "${productionSlot}" "${healthProd}" "${healthStaging}")" \
        "$(status "${json}" "${slot}")" \
        "$(tag "${json}" "${slot}")"
}

echo "$(displayHeader)"
for api in "${apis[@]}"; do 
for slot in "${slots[@]}"; do 
echo "$(displaySlot "${api}" "${slot}")"
done
done
