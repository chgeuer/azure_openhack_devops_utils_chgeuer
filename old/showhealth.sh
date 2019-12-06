#!/bin/bash

function usage {
  echo "Provide hostname and datacenter, like so: 
    $0 akstraefikopenhack1ln8.northeurope"
}

if [ $# -ne 1 ]; then
  usage
  exit 1
fi

prefix=$1 prod="${prefix}.cloudapp.azure.com/api/healthcheck" stage="stage${prod}"
function status { echo $(curl --silent --output /dev/null --write-out '%{http_code}' http://$1/$2) ; }

echo "|      |     |      |      | USER |
|      | POI | TRIP | USER | JAVA |
| PROD | $(status $prod "poi") | $(status $prod "trips")  | $(status $prod "user")  | $(status $prod "user-java")  |
| STAG | $(status $stage "poi") | $(status $stage "trips")  | $(status $stage "user")  | $(status $stage "user-java")  |"
