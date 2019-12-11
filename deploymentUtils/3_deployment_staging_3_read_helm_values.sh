#!/bin/bash
# Read helm values
#source "$( dirname "$( readlink -f "$0" )" )/_shared.sh"

# Read Azure DevOps pipeline variable HelmReleaseName
echo "Using Helm release name '${HELMRELEASENAME}'"

json="$( getLiveHelmData "${HELMRELEASENAME}" )"
currentSlotName="$( prodSlot "${json}" )"
if [ "${currentSlotName}" == "" ] ; then
  echo "Cannot determine production slot"
  exit 1
fi

nextSlotName="$( nextSlot "${currentSlotName}" )"

# Output values into the Azure DevOps current pipeline
echo "##vso[task.setvariable variable=currentSlotName]${currentSlotName}"
echo "##vso[task.setvariable variable=nextSlotName]${nextSlotName}"
