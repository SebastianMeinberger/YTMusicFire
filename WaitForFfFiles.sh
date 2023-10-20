#!/bin/bash
firefox --headless --new-instance --profile test/usr/share/ytmusicfire/YTMusicFireUser &
until [ -f $1$2extensions.json ] && [ -f $1$2addonStartup.json.lz4 ]
do
	sleep 1
done
