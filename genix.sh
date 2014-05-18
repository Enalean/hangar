#!/bin/bash

set -e

DOCKER_HOST=/var/run/docker.sock
JQ="jq --monochrome-output --raw-output"
NGINX_CONF=/mnt/proxy

get_docker() {
    nc -U $DOCKER_HOST | sed '1,/^\r$/d'
}

get_virtual_host() {
    echo -e "GET /containers/$1/json HTTP/1.1\r\n" | get_docker | $JQ '.Config.Env[]' | egrep '^VIRTUAL_HOST=' | cut -d'=' -f2
}

get_ip_address() {
    echo -e "GET /containers/$1/json HTTP/1.1\r\n" | get_docker | $JQ '.NetworkSettings.IPAddress'
}

generate_nginx_conf() {
    echo "Generate nginx configuration"
    rm -f "$NGINX_CONF.new"
    echo -e "GET /containers/json HTTP/1.1\r\n" | get_docker | $JQ '.[].Id' | while read container; do
	VIRTUAL_HOST=$(get_virtual_host $container)
	if [ ! -z "$VIRTUAL_HOST" ]; then	
	    IPADDRESS=$(get_ip_address $container)
	    echo "Found: $VIRTUAL_HOST $IPADDRESS"
	    cat nginx.tmpl | \
		sed -e "s/%host%/$VIRTUAL_HOST/" | \
		sed -e "s/%ip%/$IPADDRESS/" >> "$NGINX_CONF.new"
	fi
    done
    mv "$NGINX_CONF.new" "$NGINX_CONF"
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
echo -e "GET /events HTTP/1.1\r\n" | nc -U $DOCKER_HOST | while read event; do
    is_reload_event $event && generate_nginx_conf
done
