#!/bin/sh
echo "Pragma: no-cache"
echo "Cache-control: no-cache"
echo "Connection: close"
echo "Content-type: application/json"
echo ""

cat /usr/share/mobile-broadband-provider-info/serviceproviders.json

