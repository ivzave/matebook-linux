#!/bin/sh

case "$1/$2" in
	post/*)
		echo resetting camera flash after sleep
		i2cset -y -f 7 0x4c 0x28 0
		;;
esac
