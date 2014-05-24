#!/bin/bash

set -e

service nginx start

sleep 1

./genix.sh
