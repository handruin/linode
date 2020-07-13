#!/bin/bash

HOME_DIR="/home"
NGINX_SITE_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITE_ENABLE="/etc/nginx/sites-enabled"
NGINX_SNIPPET_CONF_LOC="/etc/nginx/snippets"

enable_ssl() {

	local website=$1

	#TODO - make sure website domain name resolves before proceeding...otherwise this breaks.

	if [ -n "${website}" ]; then

cat > ${NGINX_SNIPPET_CONF_LOC}/ssl-${website}.conf <<EOF
ssl_certificate /etc/letsencrypt/live/${website}/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/${website}/privkey.pem;
EOF

		sed -i "s/\#listen 443 ssl http2\;/listen 443 ssl http2\;/g" ${NGINX_SITE_AVAILABLE}/${website}
		sed -i "s/\#include snippets\/ssl-${website}.conf\;/include snippets\/ssl-${website}.conf\;/g" ${NGINX_SITE_AVAILABLE}/${website}
		sed -i "s/\#include snippets\/ssl-params.conf\;/include snippets\/ssl-params.conf\;/g" ${NGINX_SITE_AVAILABLE}/${website}

		echo "Configuring Let's Encrypt".

		letsencrypt certonly -a webroot --webroot-path=${HOME_DIR}/${website%.*}/public_html -d ${website} -d www.${website} --agree-tos --keep-until-expiring

		echo "Testing the config passes nginx tests..."
                nginx -t

                if [ "$?" == 0 ]; then
                        echo "Restarting nginx to apply new site ${website}..."
                        service nginx restart
                else
                        echo "The nginx config test failed!!!"
                fi
	else
		echo "No domain given.  Please enter a domain without the www. (e.g. example.com)"
	fi
}

echo "Enabling ssl for domain: $1"
enable_ssl $1

