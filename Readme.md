hangar is a tool that generate nginx reverse proxy configuration out based
on docker events and docker containers introspection.

Inspired from https://github.com/jwilder/docker-gen 

It's meant be be used with enalean/hangar-proxy

How to use it ?
===============

    # First start the reverse proxy
    $> docker run -d --name=hangar-proxy -p 80:80 enalean/hangar-proxy

    # Attach the configuration generator
    $> docker run -d -v /var/run/docker.sock:/var/run/docker.sock --volumes-from=hangar-proxy enalean/hangar
