#!/bin/bash

#
# Persist helm values in a variable group
#

variableGroupName="$(helmReleaseName)"
variableGroupId="1"

body="{ \"variables\": { \
            \"currentSlotName\": { \"value\": \"$(currentSlotName)\" }, \
            \"nextSlotName\": { \"value\": \"$(nextSlotName)\" } }, \
        \"name\": \"${variableGroupName}\", \"type\": \"Vsts\" }"

restApiVersion="5.1-preview.1"
url="${SYSTEM_TASKDEFINITIONSURI}${SYSTEM_TEAMPROJECT}/_apis/distributedtask/variablegroups/${variableGroupId}?api-version=${restApiVersion}"

accessToken="${SYSTEM_ACCESSTOKEN}"

echo "url: ${url}"
echo "body: ${body}"

curl --request PUT --silent \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${accessToken}" \
    --data "${body}" "${url}"
