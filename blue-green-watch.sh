#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl', 'printf"
# Author: Christian Geuer-Pollmann <chgeuer@microsoft.com>

#source ./_shared.sh
#source "$( dirname "$( readlink -f "$0" )" )/_shared.sh"
source "${SYSTEM_ARTIFACTSDIRECTORY}/_deploymentUtils/deploymentUtils/_shared.sh"

declare -A helmValues
for releaseName in "${releaseNames[@]}"; do
    helmValues["${releaseName}"]="$( getLiveHelmData "${releaseName}" )";
done
function getCachedHelmData { local releaseName="$1" ; echo "${helmValues["${releaseName}"]}" ; }

declare format="| %-15s | %-5s | %-10s | %-6s | %-7s | %6s |"
function displayHeader { printf "${format}\n" "helm release" "slot" "role" "health" "status" "tag" ; }
function displaySep { printf "${format}\n" "---------------" "-----" "----------" "------" "-------" "------" ; }
function displayProd { local s1="$1" s2="$2"; if [ "${s1}" == "${s2}" ]; then echo "Production"; else echo "Staging"; fi ; }
function displayHealth { if [ $1 == $2 ]; then echo "$3"; else echo "$4"; fi ; }
function displayStatus { echo "$( getJsonVal "$1" ".$2.enabled" | sed 's/true/running/g' | sed 's/false/empty/g' )" ; }
function displayTag { local json="$1" slot="$2"; echo "$( getJsonVal "${json}" ".${slot}.tag" )" ; }
function displaySlot {
    local releaseName="$1"
    local slot="$2"
    local json="$( getCachedHelmData "${releaseName}" )"
    local productionSlot="$( prodSlot "${json}" )"
    local healthProd="$( httpStatus "http://$( healthUrl "${json} ")" )"
    local healthStaging="$( httpStatus "http://stage$( healthUrl "${json}" )" )"
    printf "${format}" "${releaseName}" "${slot}" \
        "$( displayProd   "${slot}" "${productionSlot}" )" \
        "$( displayHealth "${slot}" "${productionSlot}" "${healthProd}" "${healthStaging}" )" \
        "$( displayStatus "${json}" "${slot}" )" \
        "$( displayTag    "${json}" "${slot}" )"
}

echo "$( displayHeader )"
for slot in "${slots[@]}"; do
echo "$( displaySep )"
for releaseName in "${releaseNames[@]}"; do 
echo "$( displaySlot "${releaseName}" "${slot}" )"
done
done
