#!/bin/bash
firefox --headless --new-instance --profile $1$2 &
until [ -f $1$2extensions.json ] && [ -f $1$2addonStartup.json.lz4 ]
do
	sleep 1
done
# Firefox needs to be killed manually, since it persits even after its shell is killed
kill $(jobs -p) 
