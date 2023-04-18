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

#INTERVAL=0.04
INTERVAL=0.04

INGAME_SENSITIVITY=13.4
# TODO unused

FORWARD=w
BACKWARD=s
LEFT=a
RIGHT=d

##### shooting

CLICK_ACTIVATION_KEY=$NUMPAD_7
CLICK_DEACTIVATION_KEY=$NUMPAD_8

CLICK_ON_EVERY_SPIN=0 # TODO activating this make the spinning much slower
MOUSE_CLICKER_INTERVAL=0.01

########## constants

# -16363 is not enough (goes a bit to the right)
# -16364 is too much (goes a bit to the left)
PIXELS_360=-16363
PIXELS_180=$(($PIXELS_360 / 2))
PIXELS_90_LEFT=$(($PIXELS_360 / 4))
PIXELS_45_LEFT=$(($PIXELS_360 / 8))
# TODO works only on sensitivity 1.0

CMD_START_CLICK='start clicking'
CMD_STOP_CLICK='stop clicking'

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

########## fncs

keylogger(){
	xinput test-xi2 --root 3 | grep -A2 --line-buffered RawKeyRelease | while read -r line;
	do
	    if [[ $line == *"detail"* ]];
	    then
	        key=$(echo $line | sed "s/[^0-9]*//g")
	    fi

	    echo "$key"
	done
}

mouse_mover(){

	active=0

	while true; do
		read -t ${INTERVAL} -r key

    	case "${key}" in

			${ACTIVATION_KEY})
				if [ ${active} = 0 ]; then
					active=1
				
					looking_at=0
				
					echo 'activated'
				fi
				;;

			${DEACTIVATION_KEY})
				if [ ${active} = 1 ]; then
					active=0

					send_keyup $FORWARD
					send_keyup $BACKWARD
					send_keyup $LEFT
					send_keyup $RIGHT
					
					echo 'deactivated'
				fi
				;;
			
			$CLICK_ACTIVATION_KEY)
				echo $CMD_START_CLICK
				;;

			$CLICK_DEACTIVATION_KEY)
				echo $CMD_STOP_CLICK
				;;
    	
    		"")
    			if [ ${active} = 1 ]; then

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
    			fi
    			;;

			*)
				#echo "ignored event: ${key}"
				;;
    	esac
	done
}

mouse_clicker(){

	active=0

	while true; do
		read -t $MOUSE_CLICKER_INTERVAL -r cmd
		read_err=$?

		case $cmd in
			$CMD_START_CLICK)
				active=1
				;;
			$CMD_STOP_CLICK)
				active=0
				;;
			"")
				# TODO we might not be able to print empty lines

				if [ $active = 0 ]; then
					continue
				fi

				click_mouse
				;;
			*)
				echo $cmd
				;;
		esac
	done
}

########## main

keylogger | mouse_mover | mouse_clicker
