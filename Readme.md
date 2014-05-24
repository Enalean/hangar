hangar is a tool that generate nginx reverse proxy configuration out based
on docker containers introspection.

Inspired from https://github.com/jwilder/docker-gen 

It's meant be be used with enalean/hangar-proxy

How to use it ?
===============

    # First start the reverse proxy
    $> docker run -d --name=hangar-proxy -p 80:80 enalean/hangar-proxy

    # Attach the configuration generator
    $> docker run -v /var/run/docker.sock:/var/run/docker.sock --volumes-from=hangar-proxy enalean/hangar

Note 1: it will automatically generate a reverse proxy configuration for any containers that have 'VIRTUAL_HOST'
or 'PUBLIC_NAME' environmnent variable.

Note 2: in a first attempt this tool was using docker's /events stream but I didn't manage to have it
reliable enough so it's meant to be launched "when needed" (ie. when you start or stop a container).
