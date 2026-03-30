#!/usr/bin/env bash

$TERMINAL --app-id=$(basename $1) -e "$1" "${@:2}"
