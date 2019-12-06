#!/bin/bash

echo "This is not working -- $(System.AccessToken) --"

echo "To see the access token, run
echo \"$( echo "$(System.AccessToken)" | base64 )\" | base64 -d
"
