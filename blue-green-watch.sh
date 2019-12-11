#!/bin/bash
# Requires 'helm', 'yq', 'jq', 'sed', 'curl', 'printf"
# Author: Christian Geuer-Pollmann <chgeuer@microsoft.com>

#source ./_shared.sh
#source "$( dirname "$( readlink -f "$0" )" )/_shared.sh"

function installHelm { 
    echo >&2 "Installing helm"
    mkdir -p ./helm
    curl --silent \
        https://storage.googleapis.com/kubernetes-helm/helm-v2.14.3-linux-amd64.tar.gz \
        -o helm-v2.14.3-linux-amd64.tar.gz
    tar xvfz helm-v2.14.3-linux-amd64.tar.gz -C ./helm 2>&1 >/dev/null
    rm helm-v2.14.3-linux-amd64.tar.gz
    #echo "alias helm=\"$(pwd)/helm/linux-amd64/helm\"" >> ~/.bash_aliases
    echo "PATH=\"$(pwd)/helm/linux-amd64:\$PATH\"" >> ~/.profile
    echo "PATH=\"$(pwd)/helm/linux-amd64:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
}

hash helm 2>/dev/null || { installHelm ; }
if ! [[ "$(helm version --short)" =~ "2.14.3" ]]; then installHelm ; fi

hash yq 2>/dev/null || { 
    pip install yq --user 2>&1 >/dev/null ; 
    echo "PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.profile
    echo "PATH=\"\$HOME/.local/bin:\$PATH\"" > ~/.bashrc
    source ~/.bashrc
}

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

declare -A helmValues
for releaseName in "${releaseNames[@]}"; do
    helmValues["${releaseName}"]="$( getLiveHelmData "${releaseName}" )";
done
function getCachedHelmData { local releaseName="$1" ; echo "${helmValues["${releaseName}"]}" ; }

declare format="| %-15s | %-5s | %-10s | %-6s | %-7s | %6s |"
function displayHeader { printf "${format}\n" "helm release" "slot" "role" "health" "status" "tag" ; }
function displaySep { printf "${format}\n" "---------------" "-----" "----------" "------" "-------" "------" ; }
function displayProd { local s1="$1" s2="$2"; if [ "${s1}" == "${s2}" ]; then echo "Production"; else echo "Staging"; fi ; }
function displayHealth { if [[ $1 == $2 ]]; then echo "$3"; else echo "$4"; fi ; }
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
