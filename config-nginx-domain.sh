#!/bin/bash

HOME_DIR="/home"
NGINX_SITE_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITE_ENABLE="/etc/nginx/sites-enabled"
NGINX_SNIPPET_CONF_LOC="/etc/nginx/snippets"

create_domain() {

	local website=$1

	if [ -n "${website}" ]; then
		
		echo "Adding user ${website%.*}"	
		adduser "${website%.*}" --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password --quiet
		echo "Changing password to ${website%.*}"
		echo "${website%.*}:${website%.*}" | chpasswd
		echo "Creating directory structure under ${HOME_DIR}/${website%.*}/"
		mkdir -p ${HOME_DIR}/${website%.*}/
		mkdir -p ${HOME_DIR}/${website%.*}/public_html
		chmod 755 ${HOME_DIR}/${website%.*}/public_html
		mkdir -p ${HOME_DIR}/${website%.*}/log
		chmod 755 ${HOME_DIR}/${website%.*}/log
		mkdir -p ${HOME_DIR}/${website%.*}/backups
		chmod 755 ${HOME_DIR}/${website%.*}/backups
		chown -R ${website%.*}:${website%.*} ${HOME_DIR}/${website%.*}/
		chmod 711 ${HOME_DIR}/${website%.*}/
		cp allbackup.sh ${HOME_DIR}/${website%.*}/
		cp index.html ${HOME_DIR}/${website%.*}/public_html/
		chmod 755 ${HOME_DIR}/${website%.*}/allbackup.sh
		chown ${website%.*}:${website%.*} ${HOME_DIR}/${website%.*}/allbackup.sh
		chown -R ${website%.*}:${website%.*} ${HOME_DIR}/${website%.*}/public_html


cat > ${NGINX_SITE_AVAILABLE}/${website} <<EOF
server {
        listen 80;

        # SSL configuration
        #
        #listen 443 ssl http2;

	root ${HOME_DIR}/${website%.*}/public_html;

        # Add index.php to the list if you are using PHP
        index index.php index.html index.htm index.nginx-debian.html;

        server_name ${website} www.${website};
        #include snippets/ssl-${website}.conf;
        #include snippets/ssl-params.conf;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files \$uri \$uri/ =404;
        }

	location /phpmyadmin {
                auth_basic "Admin Login";
                auth_basic_user_file /etc/nginx/pma_pass;
        }

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        location ~ \.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        location ~ /\.ht {
                deny all;
        }

        location ~ /.well-known {
                allow all;
        }

	location = /favicon.ico {
		log_not_found off;
		access_log off;
	}

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	access_log ${HOME_DIR}/${website%.*}/log/access.log;
	error_log ${HOME_DIR}/${website%.*}/log/error.log;
}

EOF

		echo "Enabling website under nginx"
		ln -s ${NGINX_SITE_AVAILABLE}/${website} ${NGINX_SITE_ENABLE}/${website}

		echo "Testing the config passes nginx tests..."
		nginx -t

		if [ "$?" == 0 ]; then	
			echo "Restarting nx to apply new site ${website}..."
			service nginx restart
		else
			echo "The nginx config test failed!!!"
		fi
		echo "New website created!"
		
	else
		echo "No website defined.  Please only use domain.com without 'www'"
		exit 1
	fi

}


echo "Creating new domain $1"
create_domain $1
