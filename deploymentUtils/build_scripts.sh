#!/bin/bash

cd deploymentUtils

cat _shared.sh > 3.sh
cat 3_deployment_staging_3_read_helm_values.sh >> 3.sh
chmod +x 3.sh

cat _shared.sh > 5.sh
cat 5_deployment_production_1_read_helm_values.sh >> 5.sh
chmod +x 5.sh

cat _shared.sh > blue-green-watch.sh
cat _blue-green-watch.sh >> blue-green-watch.sh
chmod +x blue-green-watch.sh
