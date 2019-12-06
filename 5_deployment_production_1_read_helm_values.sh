#!/bin/bash
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
