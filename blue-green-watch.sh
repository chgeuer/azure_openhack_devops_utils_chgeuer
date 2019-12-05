#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl', 'printf"
# Author: Christian Geuer-Pollmann <chgeuer@microsoft.com>
declare slots=( "blue" "green" ) releaseNames=( "api-poi" "api-trip" "api-user" "api-user-java" ) format="| %-15s | %-5s | %-10s | %-6s | %-7s | %6s | %s"
declare -A helmValues
function getCachedHelmData { local releaseName="$1" ; echo "${helmValues["${releaseName}"]}" ; }
for releaseName in "${releaseNames[@]}"; do helmValues["${releaseName}"]="$(helm get values --all "${releaseName}" | yq . )"; done

function indexOf { local slot="$1" ; local i="$(echo ${slots[@]} | tr -s " " "\n" | grep -n "${slot}" | cut -d":" -f 1)" ; echo "$((i-1))" ; }
function numberOfSlots { echo "${#slots[@]}" ; }
function indexNextSlot { local slot="$1" ; curr=$(indexOf "${slot}") ; len=$(numberOfSlots) ; echo "$(( (curr + 1) % len ))" ;}
function nextSlot { local slot="$1"; n="$(indexNextSlot "${slot}")" ; echo "${slots[$n]}" ; }
function getJsonVal { echo $(echo "$1" | jq -r "$2") ; }
function prodSlot { echo $(getJsonVal "$1" ".productionSlot") ; }
function status { echo $(getJsonVal "$1" ".$2.enabled" | sed 's/true/running/g' | sed 's/false/empty/g') ; }
function tag { local json="$1" slot="$2"; echo $(getJsonVal "${json}" ".${slot}.tag") ; }
function healthHost { echo "$(getJsonVal "$1" .ingress.rules.endpoint.host)" ; }
function healthPath { echo "$(getJsonVal "$1" ".ingress.rules.endpoint.paths[] | select(.path | contains(\"healthcheck\")) | .path")" ; }
function healthURL { echo "$(healthHost "$1")$(healthPath "$1")" ; }
function http_status { echo $(curl --silent --output /dev/null --write-out '%{http_code}' $1) ; }
function displayProd { local s1="$1" s2="$2"; if [ "${s1}" == "${s2}" ]; then echo "Production"; else echo "Staging"; fi ; }
function displayHealth { if [ $1 == $2 ]; then echo "$3"; else echo "$4"; fi ; }
function displayHeader { printf "${format}\n" "helm release" "slot" "role" "health" "status" "tag" ; }
function displaySep { printf "${format}\n" "---------------" "-----" "----------" "------" "-------" "------" "xxx"; }
function displaySlot {
    local releaseName="$1" slot="$2" json=$(getCachedHelmData ${releaseName})
    local productionSlot=$(prodSlot "${json}")
    local healthProd=$(http_status "http://$(healthURL "${json}")")
    local healthStaging=$(http_status "http://stage$(healthURL "${json}")")
    printf "${format}" "${releaseName}" "${slot}" \
        "$(displayProd "${slot}" "${productionSlot}")" \
        "$(displayHealth "${slot}" "${productionSlot}" "${healthProd}" "${healthStaging}")" \
        "$(status "${json}" "${slot}")" \
        "$(tag "${json}" "${slot}")" \
        "$(nextSlot "${slot}")"
}

echo "$(displayHeader)"
for slot in "${slots[@]}"; do 
echo "$(displaySep)"
for releaseName in "${releaseNames[@]}"; do 
echo "$(displaySlot "${releaseName}" "${slot}")"
done
done
