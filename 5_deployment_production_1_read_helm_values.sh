#!/bin/bash

#
# Download vars from variable group REST API
#

variableGroupName="$(helmReleaseName)"
variableGroupId="1"

restApiVersion="5.1-preview.1"
url="${SYSTEM_TASKDEFINITIONSURI}${SYSTEM_TEAMPROJECT}/_apis/distributedtask/variablegroups?groupName=${variableGroupName}&api-version=${restApiVersion}"

json="$( curl --silent --request GET --header "Authorization: Bearer $(System.AccessToken)" "${url}" )"
variables="$( echo "${json}" | jq -r ".value[] | select( .name == \"${variableGroupName}\" ) | .variables" )"
echo "JSON from variable group ${variableGroupName}: $( echo "${variables}" | jq . )"
currentSlotName="$( echo "${variables}" | jq -r ".currentSlotName.value" )"
nextSlotName="$( echo "${variables}" | jq -r ".nextSlotName.value" )"

echo "##vso[task.setvariable variable=currentSlotName]${currentSlotName}"
echo "##vso[task.setvariable variable=nextSlotName]${nextSlotName}"
