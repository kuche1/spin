#! /usr/bin/env bash

#set -e
#set -o xtrace

########## keys

NUMPAD_4=83
NUMPAD_5=84
NUMPAD_7=79
NUMPAD_8=80

########## settings

##### spinning

ACTIVATION_KEY=${NUMPAD_4}
DEACTIVATION_KEY=${NUMPAD_5}

SPIN_INTERVAL=0.04

INGAME_SENSITIVITY=13.4
# TODO unused

FORWARD=w
BACKWARD=s
LEFT=a
RIGHT=d

##### shooting

CLICK_ACTIVATION_KEY=$NUMPAD_7
CLICK_DEACTIVATION_KEY=$NUMPAD_8

CLICK_ON_EVERY_SPIN=0 # TODO activating this make the spinning much slower # TODO this should be fixed now
MOUSE_CLICKER_INTERVAL=0.01

########## constants

# -16363 is not enough (goes a bit to the right)
# -16364 is too much (goes a bit to the left)
PIXELS_360=-16363
PIXELS_180=$(($PIXELS_360 / 2))
PIXELS_90_LEFT=$(($PIXELS_360 / 4))
PIXELS_45_LEFT=$(($PIXELS_360 / 8))
# TODO works only on sensitivity 1.0

########## basic fncs

##### mouse

move_mouse(){
	x=$1
	y=$2
	xdotool mousemove_relative -- $1 $2
}

do_180(){
	move_mouse $PIXELS_180 0
}

do_90_left(){
	move_mouse $PIXELS_90_LEFT 0
}

do_45_left(){
	move_mouse $PIXELS_45_LEFT 0
}

click_mouse(){
	#xdotool click 1
	xdotool mousedown 1
	sleep 0.01
	xdotool mouseup 1
}

##### keyboard

send_key(){
	k=$1
	xdotool key $k
}

send_keydown(){
	k=$1
	xdotool keydown $k
}

send_keyup(){
	k=$1
	xdotool keyup $k
}

##### output

log(){
	>&2 echo $@
}

########## fncs

keylogger(){
	xinput test-xi2 --root 3 | grep -A2 --line-buffered RawKeyRelease | while read -r line;
	do
	    if [[ $line == *"detail"* ]];
	    then
	        key=$(echo $line | sed "s/[^0-9]*//g")
	    fi

	    echo $key
	done
}

mouse_mover(){

	active=0

	while true; do
		sleep $SPIN_INTERVAL

		while true; do
			read -t 0.001 -r key
			read_ret=$?

			if [ $read_ret != 0 ]; then
				break
			fi

			case $key in

				$ACTIVATION_KEY)
					if [ $active = 0 ]; then
						active=1
					
						looking_at=0
					
						log 'activated'
					fi
					;;

				$DEACTIVATION_KEY)
					if [ $active = 1 ]; then
						active=0

						send_keyup $FORWARD
						send_keyup $BACKWARD
						send_keyup $LEFT
						send_keyup $RIGHT
						
						log 'deactivated'
					fi
					;;

				*)
					echo $key
					;;
			esac

		done

		if [ $active = 0 ]; then
			continue
		fi

		if [ $CLICK_ON_EVERY_SPIN = 1 ]; then
			click_mouse
		fi

		case $looking_at in
			0)
				looking_at=1
				# ^
				# |
				# w

				do_45_left
				#  ^
				# <\
				# wd
				send_keydown $FORWARD
				send_keydown $RIGHT
				;;

			1)
				looking_at=2
				#  ^
				# <\
				# wd
				send_keyup $FORWARD

				do_45_left
				# <-
				# d
				;;

			2)
				looking_at=3
				# <-
				# d

				do_45_left
				# </
				#  v
				# ds
				send_keydown $BACKWARD
				;;
			3)
				looking_at=4
				# </
				#  v
				# ds
				send_keyup $RIGHT

				do_45_left
				# |
				# v
				# d
				;;
			4)
				looking_at=5
				# |
				# v
				do_45_left
				# \>
				# v
				send_keydown $LEFT
				;;
			5)
				looking_at=6
				# \>
				# v
				send_keyup $BACKWARD
				do_45_left
				# ->
				;;
			6)
				looking_at=7
				# ->
				do_45_left
				# ^
				# />
				send_keydown $FORWARD
				;;
			7)
				looking_at=0
				# ^
				# />
				send_keyup $LEFT
				do_45_left
				# ^
				# |
				;;
			*)
				echo "ERROR unknown state looking_at=$looking_at"
				;;
		esac

	done
}

mouse_clicker(){

	active=0

	while true; do
		sleep $MOUSE_CLICKER_INTERVAL

		while true; do
			read -t 0.001 -r key
			read_ret=$?

			if [ $read_ret != 0 ]; then
				break
			fi

			case $key in
				$CLICK_ACTIVATION_KEY)
					active=1
					;;

				$CLICK_DEACTIVATION_KEY)
					active=0
					;;

				*)
					echo $key
					;;
			esac
		done

		if [ $active = 0 ]; then
			continue
		fi

		click_mouse

	done
}

########## main

keylogger | mouse_mover | mouse_clicker > /dev/null

# read -t 0.001 -r var
# echo var=$var ret=$?
