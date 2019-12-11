#!/bin/bash

declare slots=( 'blue' 'green' )
declare releaseNames=( "api-poi" "api-trip" "api-user" "api-user-java" )

function indexOf { local slot="$1" ; local i="$(echo ${slots[@]} | tr -s " " "\n" | grep -n "${slot}" | cut -d":" -f 1)" ; echo "$((i-1))" ; }
function numberOfSlots { echo "${#slots[@]}" ; }
function indexNextSlot { local slot="$1" ; curr=$(indexOf "${slot}") ; len=$(numberOfSlots) ; echo "$(( (curr + 1) % len ))" ; }
function nextSlot { local slot="$1"; n="$( indexNextSlot "${slot}" )" ; echo "${slots[$n]}" ; }

function getJsonVal { echo "$( echo "$1" | jq -r "$2" )" ; }
function prodSlot   { echo "$( getJsonVal "$1" ".productionSlot" )" ; }

function healthHost { echo "$( getJsonVal "$1" ".ingress.rules.endpoint.host" )" ; }
function healthPath { echo "$( getJsonVal "$1" ".ingress.rules.endpoint.paths[] | select(.path | contains(\"healthcheck\")) | .path" )" ; }
function healthUrl  { echo "$( healthHost "$1" )$( healthPath "$1" )" ; }
function httpStatus { echo "$( curl --silent --output /dev/null --write-out '%{http_code}' $1 )" ; }

function getLiveHelmData { local releaseName="$1" ; echo "$( helm get values --all "${releaseName}" | yq . )" ; }
