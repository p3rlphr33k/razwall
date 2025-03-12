#
#        +-----------------------------------------------------------------------------+
#        | RazWall Firewall                                                             |
#        +-----------------------------------------------------------------------------+
#        | Copyright (c) 2024 RazWall                                                  |
#        |                                                                             |
#        | This program is free software; you can redistribute it and/or               |
#        | modify it under the terms of the GNU General Public License                 |
#        | as published by the Free Software Foundation; either version 2              |
#        | of the License, or (at your option) any later version.                      |
#        |                                                                             |
#        | This program is distributed in the hope that it will be useful,             |
#        | but WITHOUT ANY WARRANTY; without even the implied warranty of              |
#        | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               |
#        | GNU General Public License for more details.                                |
#        |                                                                             |
#        | You should have received a copy of the GNU General Public License           |
#        | along with this program; if not, write to the Free Software                 |
#        | Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA. |
#        | http://www.fsf.org/                                                         |
#        +-----------------------------------------------------------------------------+
#

%strings = (
  'nw_adsl_type' => _('ADSL type'),
  'nw_auth_method' => _('Authentication method'),
  'nw_automatic' => _('automatic'),
  'nw_lan2_descr' => _('network segment for wireless clients (WIFI)'),
  'nw_lan2' => _('LAN2'),
  'nw_chap' => _('CHAP'),
  'nw_concentrator_name' => _('Concentrator name'),
  'nw_description' => _('Description'),
  'nw_dhcp' => _('RFC1483 dhcp'),
  'nw_dial_telephone' => _('Phone number to dial'),
  'nw_dns_manual' => _('manual DNS configuration'),
  'nw_dns_quest' => _('DNS'),
  'nw_dns' => _('configure DNS resolver'),
  'nw_domainname' => _('Domainname'),
  'nw_encapsulation' => _('Encapsulation'),
  'nw_end_msg' => _('Your configuration has been saved. Please wait until the dependent services have been reloaded. This may take up to 20 seconds. Enjoy!'),
  'nw_field_blank' => _('This field may be blank.'),
  'nw_final_msg' => _('Congratulations!<br>Network setup is ready, click Ok to apply the new configuration.'),
  'nw_gateway' => _('Default gateway'),
  'nw_lan_changed_explain' => _('The IP address of LAN has been changed. After relaunch (about 20 seconds) you can reach the webinterface on the new IP address by following the link'),
  'nw_lan_changed_proxy' => _('Remember to check if IP address blocks of services are still configured as you wish. Mainly check the configuration of "Network based access control" of the HTTP Proxy.'),
  'nw_lan_changed_link' => _('Web interface on the new address'),
  'nw_lan_descr' => _('trusted, internal network (LAN)'),
  'nw_lan' => _('LAN'),
  'nw_hostname' => _('Hostname'),
  'nw_interface' => _('Interfaces'),
  'nr_interfaces' => _('Number of interfaces'),
  'hardware_information' => _('Hardware information'),
  'nw_dhcp_enable' => _('Enable DHCP server on this zone'),

  'nw_ip' => _('IP address'),
  'nw_last' => _('OK, apply configuration'),
  'nw_link' => _('Link'),
  'nw_mac' => _('MAC'),
  'nw_manual' => _('manual'),
  'nw_mask' => _('network mask'),
  'nw_modemdriver' => _('Please select the driver of your modem'),
  'nw_mtu' => _('MTU'),
  'nw_next' => _('>>>'),
  'nw_cancel' => _('Cancel'),
  'nw_dmz_descr' => _('network segment for servers accessible from internet (DMZ)'),
  'nw_dmz' => _('DMZ'),
  'nw_papchap' => _('PAP or CHAP'),
  'nw_pap' => _('PAP'),
  'nw_port' => _('Port'),
  'nw_pppoa' => _('PPPoA'),
  'nw_pppoe_plugin' => _('PPPoE plugin'),
  'nw_pppoe' => _('PPPoE'),
  'nw_prev' => _('<<<'),
  'nw_network_modes' => _('Network modes'),
  'nw_wan_descr' => _('untrusted, internet connection (WAN)'),
  'nw_wan_is_dhcp' => _('WAN gets the data from DHCP.'),
  'nw_wan' => _('WAN'),
  'nw_wan_stealth' => ('Outgoing Interface'),
  'nw_static_gw' => _('Gateway'),
  'nw_static_ip' => _('Static ip'),
  'nw_static_netmask' => _('Netmask'),
  'nw_static' => _('RFC1483 static ip'),
  'nw_timeout' => _('Hang up after minutes of inactivity'),
  'nw_use_both_channels' => _('Use both B-Channels'),
  'nw_use_telephone' => _('Your phone number to be used to dial out'),
  'nw_vci' => _('VCI number'),
  'nw_vpi' => _('VPI number'),

  'nw_dns1' => _('DNS 1'),
  'nw_dns2' => _('DNS 2'),
  'password' => _('Password'),
  'service' => _('Service'),
  'username' => _('Username'),

  'nw_noautoconnect' => _('Do not automatically connect on boot'),
  'nw_mac_spoof' => _('Spoof MAC address with'),
  'nw_additionalips' => _('Add additional addresses (one IP/Netmask or IP/CIDR per line) '),

  'nw_comport' => _('Please select the serial port of your modem'),
  'nw_modemtype' => _('Please select the modem type'),
  'nw_analog_modem' => _('Simple analog modem'),
  'nw_hsdpa_modem' => _('UMTS/HSDPA modem'),
  'nw_cdma_modem' => _('UMTS/CDMA modem'),
  'nw_speed' => _('Baud-rate'),
  'nw_apn' => _('Access Point Name'),
  'nw_device' => _('Device'),

  'nw_mm_select_modem' => _('Please select modem'),
  'nw_mm_modem_type' => _('Modem type'),
  'nw_mm_identifier' => _('Identifier/IMEI'),
  'nw_mm_status' => _('Status'),
  'nw_mm_select_country' => _("Select country"),
  'nw_mm_select_provider' => _("Select provider"),
  'nw_mm_select_apn' => _("Select APN"),

  'nw_admin_mail' => _('Admin email address'),
  'nw_mail_from' => _('Sender email address'),
  'nw_mail_smarthost' => _('Address of smarthost'),
);

1;
