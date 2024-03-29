#!/bin/bash

declare slots=( "blue" "green" ) 
function indexOf { local slot="$1" ; local i="$(echo ${slots[@]} | tr -s " " "\n" | grep -n "${slot}" | cut -d":" -f 1)" ; echo "$((i-1))" ; }
function numberOfSlots { echo "${#slots[@]}" ; }
function indexNextSlot { local slot="$1" ; curr=$(indexOf "${slot}") ; len=$(numberOfSlots) ; echo "$(( (curr + 1) % len ))" ;}
function nextSlot { local slot="$1"; n="$(indexNextSlot "${slot}")" ; echo "${slots[$n]}" ; }
function getLiveHelmData { local releaseName="$1" ; echo "$(helm get values --all "${releaseName}" | yq . )" ; }
function getJsonVal { echo $(echo "$1" | jq -r "$2") ; }
function prodSlot { echo $(getJsonVal "$1" ".productionSlot") ; }

# Read Azure DevOps pipeline variable Helm.ReleaseName
api="${HELM_RELEASENAME}"
json="$(getLiveHelmData "${api}")"
currentSlot="$(prodSlot "${json}")"
nextSlotName="$(nextSlot "${currentSlot}")"

echo "##vso[task.setvariable variable=openhack.currentSlot]${currentSlot}"
echo "##vso[task.setvariable variable=openhack.nextSlot]${nextSlotName}"
