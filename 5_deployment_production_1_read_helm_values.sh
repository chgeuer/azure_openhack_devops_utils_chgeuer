#!/bin/bash
#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl', 'printf"
# Author: Christian Geuer-Pollmann <chgeuer@microsoft.com>
source ./_shared.sh

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
# Download vars from variable group REST API

variableGroupName="${HELMRELEASENAME}"
variableGroupId="1"

restApiVersion="5.1-preview.1"
url="${SYSTEM_TASKDEFINITIONSURI}${SYSTEM_TEAMPROJECT}/_apis/distributedtask/variablegroups?groupName=${variableGroupName}&api-version=${restApiVersion}"

json="$( curl --silent --request GET --header "Authorization: Bearer ${SYSTEM_ACCESSTOKEN}" "${url}" )"
variables="$( echo "${json}" | jq -r ".value[] | select( .name == \"${variableGroupName}\" ) | .variables" )"

# echo "JSON from variable group ${variableGroupName}: $( echo "${variables}" | jq . )"
currentSlotName="$( echo "${variables}" | jq -r ".currentSlotName.value" )"
if [ "${currentSlotName}" == "" ] ; then
  echo "Cannot determine production slot"
  exit 1
fi

nextSlotName="$( echo "${variables}" | jq -r ".nextSlotName.value" )"

# Output values into the Azure DevOps current pipeline
echo "##vso[task.setvariable variable=currentSlotName]${currentSlotName}"
echo "##vso[task.setvariable variable=nextSlotName]${nextSlotName}"
