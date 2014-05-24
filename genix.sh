#!/bin/bash

set -e

DOCKER_HOST=/var/run/docker.sock
JQ="jq --monochrome-output --raw-output"
NGINX_CONF=/mnt/proxy
CURL="curl --silent --show-error"


get_docker() {
    nc -U $DOCKER_HOST | sed '1,/^\r$/d'
}

get_env_value() {
    $CURL -XGET "http://localhost:4242/containers/$1/json" | $JQ '.Config.Env[]' | egrep "^$2=" | cut -d'=' -f2
}

get_virtual_host() {
    vhost=$(get_env_value $1 "VIRTUAL_HOST")
    [ -z "$vhost" ] && vhost=$(get_env_value $1 "PUBLIC_NAME")
    echo $vhost
}

get_ip_address() {
    $CURL -XGET "http://localhost:4242/containers/$1/json" | $JQ '.NetworkSettings.IPAddress'
}

generate_nginx_conf() {
    echo "$(date) Generate nginx configuration"
    rm -f "$NGINX_CONF.new"
    $CURL -XGET "http://localhost:4242/containers/json" | $JQ '.[].Id' | while read container; do
	echo "Inspect $container"
	VIRTUAL_HOST=$(get_virtual_host $container)
	if [ ! -z "$VIRTUAL_HOST" ]; then	
	    IPADDRESS=$(get_ip_address $container)
	    echo "Found: $VIRTUAL_HOST $IPADDRESS"
	    cat nginx.tmpl | \
		sed -e "s/%host%/$VIRTUAL_HOST/" | \
		sed -e "s/%ip%/$IPADDRESS/" >> "$NGINX_CONF.new"
	fi
    done
    if [ -f "$NGINX_CONF.new" ]; then
	mv "$NGINX_CONF.new" "$NGINX_CONF"
    else
	echo "*** ERROR: no valid conf generated"
    fi
}

is_reload_event() {
    status=$(echo $1 | $JQ '.status' 2>/dev/null)
    case "$status" in
	"start"|"die")
	    true;;
	*)
	    echo "*** Skip $event"
	    false;;
    esac
}

# Generate conf on load to ensure we are up-to-date on run
generate_nginx_conf

# Now listening to docker events and generate conf when needed
# echo -e "GET /events HTTP/1.1\r\n" | nc -U $DOCKER_HOST | while read event; do
#     is_reload_event $event && generate_nginx_conf
# done
