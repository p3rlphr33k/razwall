echo "Setting permissions.."

chmod 0777 /razwall/web/cgi-bin/*.pl
chmod 0777 /razwall/web/cgi-bin/*.cgi
chmod 0777 /razwall/web/cgi-bin/*.pm
chmod 0777 /razwall/web/cgi-bin/setup/step1/*.pl
chmod 0777 /razwall/web/cgi-bin/setup/step1/*.cgi
chmod 0777 /razwall/web/cgi-bin/setup/step2/*.pl
chmod 0777 /razwall/web/cgi-bin/setup/step2/*.cgi
chmod 0777 /razwall/web/cgi-bin/*.sh
chmod +x /razwall/web/cgi-bin/*.sh
chmod +x /etc/rc.d/rc.dhcpd

echo "Generating HTTP SSL Certificate.."

openssl req -x509 -nodes -days 356 -newkey rsa:4096 -keyout /razwall/web/certs/server.key -out /razwall/web/certs/server.crt -subj '/C=US/ST=ND/L=IT/O=razwall/CN=localhost'

echo "update Lilo boot manager.."

lilo

echo "RazWall package has been installed."