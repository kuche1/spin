#! /usr/bin/env bash

# pacman -S --needed xorg-xinput

#set -e
#set -o xtrace

########## keys

KEY_INS=118
KEY_HOME=110
KEY_PAGE_UP=112
KEY_DEL=119
KEY_END=115
KEY_PAGE_DOWN=117
NUMPAD_1=87
NUMPAD_2=88
NUMPAD_4=83
NUMPAD_5=84
NUMPAD_7=79
NUMPAD_8=80
NUMPAD_9=81

########## settings

##### ingame settings

INGAME_SENSITIVITY=3.0

FORWARD=w
BACKWARD=s
LEFT=a
RIGHT=d
JUMP=space

##### spinning

ACTIVATION_KEY=$NUMPAD_4
DEACTIVATION_KEY=$NUMPAD_5

SPIN_INTERVAL=0.04

MOVE_FORWARD=$KEY_HOME
MOVE_FORWARD_LEFT=$KEY_INS
MOVE_LEFT=$KEY_DEL
MOVE_BACK=$KEY_END
MOVE_RIGHT=$KEY_PAGE_DOWN
MOVE_FORWARD_RIGHT=$KEY_PAGE_UP

LOOK_FORWARD_PRIORITY=0 #5
# when this is 0 the spinbot will spin in all directions equally
# when this is 1 it will wait 1 tick (when looking forward) before continuing to spin
# when this is 5 it will wait 5 ticks (while looking forward) before continuing

##### shooting

CLICK_ACTIVATION_KEY=$NUMPAD_7
CLICK_DEACTIVATION_KEY=$NUMPAD_8

CLICK_ON_EVERY_SPIN=0 # this might make spinning slower
MOUSE_CLICKER_INTERVAL=0.01

##### jumping

BUNNYHOPPER_INTERVAL=0.01

BH_ACTIVATION_KEY=$NUMPAD_1
BH_DEACTIVATION_KEY=$NUMPAD_2

########## constants

# tested for sensitivity 1.0
# -16367 goes to the right
# -16368 goes to the left

# -32727 a bit to the right
# -32728 more than a bit to the left
PIXELS_360_RAW=-32728
PIXELS_360_SENS=0.5

PIXELS_360=$(echo "scale=4; ($PIXELS_360_RAW * $PIXELS_360_SENS) / $INGAME_SENSITIVITY" | bc)
PIXELS_45_LEFT=$(echo "scale=4; $PIXELS_360 / 8" | bc)

########## basic fncs

##### mouse

move_mouse(){
	x=$1
	y=$2
	xdotool mousemove_relative -- $1 $2
}

do_45_left(){
	move_mouse $PIXELS_45_LEFT 0
}

do_90_left(){
	do_45_left
	do_45_left
}

do_180(){
	do_90_left
	do_90_left
}

do_deg_left(){
	deg=$1
	move_mouse $(echo "scale=4; $PIXELS_360 * $deg / 360" | bc) 0
}

click_mouse(){
	#xdotool click 1
	xdotool mousedown 1
	sleep 0.01 # ideally this should be 0 as it would otherwise introduce delay
	xdotool mouseup 1
}

##### keyboard

send_key(){
	k=$1
	xdotool key $k
	#xdotool keydown $k
	#sleep 0.01
	#xdotool keyup $k
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
	# the commented code used to work but it no longer does
	# this is probable due to the output of xinput being changed
	# the old code is kept in case an older version of xinput is being used

	# xinput test-xi2 --root 3 | grep -A2 --line-buffered RawKeyRelease | while read -r line;
	# do
	#     if [[ $line == *"detail"* ]];
	#     then
	#         key=$(echo $line | sed "s/[^0-9]*//g")
	# 		echo $key
	#     fi
	# done

	xinput test-xi2 --root 3 | grep --line-buffered detail | while read -r line;
	do
		line=$(echo "$line" | cut -d ' ' -f 2)
		echo $line
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

				# debug
				$NUMPAD_9)
					do_deg_left 360
					;;

				$ACTIVATION_KEY)
					if [ $active = 0 ]; then
						active=1
					
						looking_at=0

						send_keydown $FORWARD

						no_spin_counter=0
					
						log 'spinbot activated'
					fi
					;;

				$DEACTIVATION_KEY)
					if [ $active = 1 ]; then
						active=0

						send_keyup $FORWARD
						send_keyup $BACKWARD
						send_keyup $LEFT
						send_keyup $RIGHT
						
						log 'spinbot deactivated'
					fi
					;;

				$MOVE_FORWARD|$MOVE_FORWARD_LEFT|$MOVE_LEFT|$MOVE_BACK|$MOVE_RIGHT|$MOVE_FORWARD_RIGHT)

					deg=0
					case $key in
						$MOVE_FORWARD)
							deg=0
							;;
						$MOVE_FORWARD_LEFT)
							deg=45
							;;
						$MOVE_LEFT)
							deg=90
							;;
						$MOVE_BACK)
							deg=180
							;;
						$MOVE_RIGHT)
							deg=270
							;;
						$MOVE_FORWARD_RIGHT)
							deg=315
							;;
					esac

					do_deg_left $deg

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
				if [ $no_spin_counter -lt $LOOK_FORWARD_PRIORITY ]; then
					no_spin_counter=$(($no_spin_counter + 1))
					continue
				else
					no_spin_counter=0
				fi

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
					log 'aimbot activated'
					active=1
					;;

				$CLICK_DEACTIVATION_KEY)
					active=0
					log 'aimbot deactivated'
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

bunny_hopper(){
	active=0

	while true; do
		sleep $BUNNYHOPPER_INTERVAL

		while true; do
			read -t 0.001 -r key
			read_ret=$?

			if [ $read_ret != 0 ]; then
				break
			fi

			case $key in
				$BH_ACTIVATION_KEY)
					active=1
					log 'bh activated'
					;;

				$BH_DEACTIVATION_KEY)
					active=0
					log 'aimbot deactivated'
					;;

				*)
					echo $key
					;;
			esac
		done

		if [ $active = 0 ]; then
			continue
		fi

		send_key $JUMP

	done
}

########## main

keylogger | mouse_mover | mouse_clicker | bunny_hopper > /dev/null

# keylogger
