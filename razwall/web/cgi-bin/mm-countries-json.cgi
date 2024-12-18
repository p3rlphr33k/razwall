#!/usr/bin/env python
import json

from endian.core.countries import COUNTRIES

ret = {k: str(v) for k, v in COUNTRIES.iteritems()}

print("Pragma: no-cache")
print("Cache-control: no-cache")
print("Connection: close")
print("Content-type: application/json")
print("")
print(json.dumps(ret))
