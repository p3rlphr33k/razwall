#!/usr/bin/env python
# -*- coding: utf-8 -*-
# +--------------------------------------------------------------------------+
# | Endian Firewall                                                          |
# +--------------------------------------------------------------------------+
# | Copyright (c) 2004-2016 S.p.A. <info@endian.com>                         |
# |         Endian S.p.A.                                                    |
# |         via Pillhof 47                                                   |
# |         39057 Appiano (BZ)                                               |
# |         Italy                                                            |
# |                                                                          |
# | This program is free software; you can redistribute it and/or modify     |
# | it under the terms of the GNU General Public License as published by     |
# | the Free Software Foundation; either version 2 of the License, or        |
# | (at your option) any later version.                                      |
# |                                                                          |
# | This program is distributed in the hope that it will be useful,          |
# | but WITHOUT ANY WARRANTY; without even the implied warranty of           |
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            |
# | GNU General Public License for more details.                             |
# |                                                                          |
# | You should have received a copy of the GNU General Public License along  |
# | with this program; if not, write to the Free Software Foundation, Inc.,  |
# | 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.              |
# +--------------------------------------------------------------------------+

from endian.modemmanager.enums import (
    # MM_MODEM_CAPABILITY_ANY,
    # MM_MODEM_CAPABILITY_NONE,
    MM_MODEM_STATE_CONNECTED,
    MM_MODEM_STATE_CONNECTING,
    MM_MODEM_STATE_DISABLED,
    MM_MODEM_STATE_DISABLING,
    MM_MODEM_STATE_DISCONNECTING,
    MM_MODEM_STATE_ENABLED,
    MM_MODEM_STATE_ENABLING,
    MM_MODEM_STATE_FAILED_REASON_NONE,
    MM_MODEM_STATE_FAILED_REASON_UNKNOWN,
    MM_MODEM_STATE_INITIALIZING,
    MM_MODEM_STATE_LOCKED,
    MM_MODEM_STATE_REGISTERED,
    MM_MODEM_STATE_SEARCHING,
    MM_MODEM_STATE_UNKNOWN,
    MM_MODEM_CAPABILITY_CDMA_EVDO,
    MM_MODEM_CAPABILITY_GSM_UMTS,
    MM_MODEM_CAPABILITY_IRIDIUM,
    MM_MODEM_CAPABILITY_LTE,
    MM_MODEM_CAPABILITY_LTE_ADVANCED,
    MM_MODEM_CAPABILITY_POTS,
    MM_MODEM_STATE_FAILED,
    MM_MODEM_STATE_FAILED_REASON_SIM_ERROR,
    MM_MODEM_STATE_FAILED_REASON_SIM_MISSING,
)
from endian.modemmanager.manager import ModemManager

try:
    import json
except ImportError:
    import simplejson as json

print("Pragma: no-cache")
print("Cache-control: no-cache")
print("Connection: close")
print("Content-type: application/json")
print("")


TECHNOLOGIES = (
    (MM_MODEM_CAPABILITY_LTE_ADVANCED | MM_MODEM_CAPABILITY_LTE | MM_MODEM_CAPABILITY_GSM_UMTS, "GSM"),
    (MM_MODEM_CAPABILITY_CDMA_EVDO, "CDMA"),
    (MM_MODEM_CAPABILITY_POTS, "POTS"),
    (MM_MODEM_CAPABILITY_IRIDIUM, "IRIDIUM")
)


def technology_to_string(technology):
    for mask, ret in TECHNOLOGIES:
        if mask & technology:
            return ret
    return "UNKNOWN"

STATE_TO_STR = {
    MM_MODEM_STATE_CONNECTED: "Connected",
    MM_MODEM_STATE_CONNECTING: "Connecting",
    MM_MODEM_STATE_DISABLED: "Disabled",
    MM_MODEM_STATE_DISABLING: "Disabling",
    MM_MODEM_STATE_DISCONNECTING: "Disconnecting",
    MM_MODEM_STATE_ENABLED: "Enabled",
    MM_MODEM_STATE_ENABLING: "Enabling",
    MM_MODEM_STATE_INITIALIZING: "Initializing",
    MM_MODEM_STATE_LOCKED: "Locked",
    MM_MODEM_STATE_REGISTERED: "Registered",
    MM_MODEM_STATE_SEARCHING: "Searching",
    MM_MODEM_STATE_UNKNOWN: "Unknown",
    MM_MODEM_STATE_FAILED: "Failed",
}


def status_to_string(status, failed_reason):
    state = STATE_TO_STR[status]
    if status == MM_MODEM_STATE_FAILED:
        if failed_reason == MM_MODEM_STATE_FAILED_REASON_SIM_ERROR:
            state += " (Sim ERROR)"
        elif failed_reason == MM_MODEM_STATE_FAILED_REASON_SIM_MISSING:
            state += " (Sim MISSING)"
    return state

ret = []
m = ModemManager()
for modem in m.modems:
    p = modem.props
    ret.append(
        dict(
            manufacturer=p['Manufacturer'],
            model=p['Model'],
            identifier=p['EquipmentIdentifier'],
            technology=technology_to_string(p['CurrentCapabilities']),
            status=status_to_string(p['State'], p['StateFailedReason']),
        )
    )
print json.dumps(ret)

