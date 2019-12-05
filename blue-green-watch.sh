#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl'
slot1="blue" slot2="green" apis=( "api-poi" "api-trip" "api-user" "api-user-java" )
function getJson { helm get values --all "$1" | yq . ; }
function getVal { echo $(echo "$1" | jq -r "$2") ; }
function prodSlot { echo $(getVal "$1" ".productionSlot") ; }
function status { echo $(getVal "$1" ".$2.enabled" | sed 's/true/enabled/g' | sed 's/false/disabled/g') ; }
function tag { echo $(getVal "$1" ".$2.tag") ; }
function healthHost { echo "$(getVal "$1" .ingress.rules.endpoint.host)" ; }
function healthPath { echo "$(getVal "$1" ".ingress.rules.endpoint.paths[] | select(.path | contains(\"healthcheck\")) | .path")" ; }
function healthURL { echo "$(healthHost "$1")$(healthPath "$1")" ; }
function http_status { echo $(curl --silent --output /dev/null --write-out '%{http_code}' $1) ; }
for api in "${apis[@]}"; do
  json=$( getJson ${api} )
  echo "${api} productionSlot:$(prodSlot "${json}") prod=$(http_status "http://$(healthURL "${json}")") staging=$(http_status "http://stage$(healthURL "${json}")")
    ${slot1} $(status "${json}" "${slot1}") tag=$(tag "${json}" "${slot1}")
    ${slot2} $(status "${json}" "${slot2}") tag=$(tag "${json}" "${slot2}")"
done
