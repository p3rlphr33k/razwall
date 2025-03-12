#!/usr/bin/python                                                                                                                                                                                                                  
#                                                                                                                                                                                                                                
#                                                                                                                                                                                                                                
#        +-----------------------------------------------------------------------------+                                                                                                                                         
#        | Endian Firewall                                                             |                                                                                                                                         
#        +-----------------------------------------------------------------------------+                                                                                                                                         
#        | Copyright (c) 2005-2006 Endian                                              |                                                                                                                                         
#        |         Endian GmbH/Srl                                                     |                                                                                                                                         
#        |         Bergweg 41 Via Monte                                                |                                                                                                                                         
#        |         39057 Eppan/Appiano                                                 |                                                                                                                                         
#        |         ITALIEN/ITALIA                                                      |                                                                                                                                         
#        |         info@endian.it                                                      |                                                                                                                                         
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

import cgi
import string
import os, os.path

class LiveLog:

    def __init__(self,options_dict):
	self.options_dict = options_dict
	self.allowedKeys = [ 'CLAMAV_COLOR','LIVE_CLAMAV',\
			     'DANSGUARDIAN_COLOR','LIVE_DANSGUARDIAN',\
			     'FIREWALL_COLOR', 'LIVE_FIREWALL',\
	            	     'HIGHLIGHT_COLOR','LIVE_HIGHLIGHT',\
			     'HTTPD_COLOR','LIVE_HTTPD',\
			     'OPENVPN_COLOR','LIVE_OPENVPN',\
			     'SMTP_COLOR','LIVE_SMTP',\
			     'SNORT_COLOR','LIVE_SNORT',\
			     'SQUID_COLOR','LIVE_SQUID',\
			     'SYSTEM_COLOR','LIVE_SYSTEM',\
			     'AUTOSCROLL'
			    ]
	self.settings_file = '/var/efw/logging/live_settings'
	self.old_settings = {}
	self.new_settings = self.old_settings

    def getOldSettings(self):
      try:
	f = open(self.settings_file,'r')
	settings = map(lambda x: string.strip(x), f.readlines())
	f.close()
	if len(settings) > 0:
	    for line in settings:
		line_parts = string.split(line,'=')
		if len(line_parts) > 1:
		    self.old_settings[line_parts[0]] = line_parts[1]
		else:
	    	    self.old_settings[line_parts[0]] = ''
      except Exception, inst:
        pass


    def getNewSettings(self):
	for key,value in self.options_dict.iteritems():
	    if key in self.allowedKeys:
		self.new_settings[key] = value
	    
    
    def cleanSettings(self):
        help_settings = self.new_settings.copy();
	for key, value in help_settings.iteritems():
	    if key not in self.allowedKeys:
		del self.new_settings[key]

    
    def writeSettings(self):
	writestring = ""
	try:
	    f = open(self.settings_file,'w')
	    for k,v in self.new_settings.iteritems():
		writestring = "%s%s=%s\n" %(writestring,k,v)
	    f.write(writestring)
	    f.close()
	    return 1
	except Exception:
	    return 0


### Included 
settings_types = {}
settings_types['logs_live'] = {'settings_factory':LiveLog}
settings = {}

form = cgi.FieldStorage()

for key in form.keys():
    settings[key] = form[key].value

if settings.has_key('type') and settings_types.has_key(settings['type']):
    success = 'true'
    SettingsFactory = settings_types[settings['type']]['settings_factory'](settings)
    SettingsFactory.getOldSettings()
    SettingsFactory.getNewSettings()
    SettingsFactory.cleanSettings()
    if SettingsFactory.writeSettings() == 0:
	success = 'false'
else:
    success = 'false'


print "Cache-Control: no-cache, must-revalidate\r\n"
print "Expires: Mon, 26 Jul 1997 05:00:00 GMT\r\n"
print "Pragma: no-cache\r\n"
print "Content-type: text/xml\r\n\r\n"
print "<?xml version='1.0' encoding='ISO-8859-1'?>\n<success value='%s' />\n" %(success)
