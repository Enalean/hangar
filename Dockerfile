FROM ubuntu:14.04

MAINTAINER manuel.vacelet@enalean.com

RUN apt-get -y update
RUN apt-get -y upgrade

RUN apt-get -y install netcat.openbsd
RUN apt-get -y install jq

ADD . /app
WORKDIR /app

CMD ["./genix.sh"]
