#!/bin/bash

function readBatt {
	lvlBatt=$(acpi -b | cut -d"," -f 2 | xargs | cut -d"%" -f1)
	onLine=$(acpi -a | cut -d" " -f 3)
#	echo $lvlBatt
#	echo $onLine
}

function playClip {
	ffplay -nodisp -autoexit ~/Music/battery/$1.ogg
}

notWarned=none

while [ true ]; do
	readBatt
	while [ "$onLine" == "off-line" ]; do
		if [ $lvlBatt -lt 66 ] && [ $lvlBatt -gt 59 ] && [ "$notWarned" == "none" ]; then
			notWarned=charging
			notify-send -i battery -u normal -t 5000 "Low battery level"
			playClip low
		fi
		if [ $lvlBatt -lt 60 ] && [ $lvlBatt -gt 54 ] && [ "$notWarned" != "critcharging" ]; then
			notWarned=critcharging
			notify-send -i battery -u critical "Battery level critical, connect charger"
			playClip critical
		fi
		if [ $lvlBatt -lt 55 ]; then
			playClip hibernate &
			sleep 1
			while [ $(pidof ffplay) ]; do
				sleep 1
				readBatt
				if [ "$onLine" == "on-line" ]; then
					killall ffplay
					break
				fi
			done
			if [ "$onLine" == "off-line" ]; then
				echo "shutdown -h now"
				exit
			fi
			notWarned=critcharging
		fi
		readBatt
		sleep 3
	done
	if [ "$notWarned" != "none" ]; then
		playClip $notWarned
		notWarned=none
	fi
	sleep 3
done
