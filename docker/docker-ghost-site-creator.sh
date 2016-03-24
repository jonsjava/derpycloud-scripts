#!/bin/bash
##########################
## Takes $site as input. It will create the docker container, create a folder in /docker/ 
## that has the ghost files for this site, and configures nginx. If nginx test passes, it 
## will restart nginx to apply changes
##########################
ghost_file='https://ghost.org/zip/ghost-latest.zip'
site=$1
noisySleep(){  
  notice=$1
  timer=$2
  sleep_count=0
  echo $notice
  while [ $sleep_count -lt $timer ]; do
    echo -n '.'
    sleep 1
    sleep_count=$(expr $sleep_count + 1)
  done
  echo ""
}
if [ ! -d /docker/$site ]; then
  # We're good. Let's install
  mkdir -p /docker/$site
  cur_dir=$(pwd)
  cd /docker/$site
  curl -LOk $ghost_file
  unzip ghost-latest.zip
  rm -rf ghost-latest.zip
  port_to_use=8080
  port_good='0'
  while [ "$port_good" = '0' ]; do
    if (nc -z 127.0.0.1 $port_to_use); then
      port_to_use=$(expr $port_to_use + 1)
    else
      port_good='1'
    fi
  done
  docker run --restart=always -p ${port_to_use}:2368 -v /docker/${site}/:/var/lib/ghost --name ${site} -d ghost
  noisySleep "Waiting 5 seconds for the container to come up" 5
  sed -i "s/localhost:2368/$site/g" /docker/$site/config.js
  docker stop $site
  docker start $site
  echo "server {

  listen 80;
  server_name $site ;
  add_header X-Content-Type-Options nosniff;
  add_header X-XSS-Protection \"1; mode=block\";

  location ~* ^/CFIDE {
    return 403;
  }

  location / {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header HOST \$http_host;
    proxy_set_header X-NginX-Proxy true;
    proxy_pass http://127.0.0.1:${port_to_use};
    proxy_redirect off;
  }
}
" > /etc/nginx/sites-available/${site}
  ln -s /etc/nginx/sites-available/${site} /etc/nginx/sites-enabled/${site}
  if ( nginx -t -c /etc/nginx/nginx.conf ); then
    service nginx restart
  else
    echo "Nginx config failure. Exiting"
    exit 1
  fi
else
  echo "Site already exists.  Stopping"
fi
