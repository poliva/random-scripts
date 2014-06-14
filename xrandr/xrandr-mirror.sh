#!/bin/bash
# script to mirror screen to the best available resolution on projectors
# useful for presentations, conferences, etc...
# (c) 2013 Pau Oliva Fora - @pof

# problems? rm ~/.config/monitors.xml

#xrandr --output HDMI1 --auto --same-as eDP1
#xrandr --output HDMI1 --auto --mode 1440x900 --same-as eDP1

INPUT="eDP1"
OUTPUT=$(xrandr |grep " connected" |grep -v "^${INPUT}" |cut -f 1 -d " ")

if [ -z $1 ]; then
	INPUT_RES=$(xrandr |grep -A1 "^${INPUT}" |tail -n 1 |awk '{print $1}')
	RES=$(xrandr |grep -A15 "^${OUTPUT}" |grep -B15 "connected" |awk '{print $1}' |grep "[0-9][0-9][0-9]x[0-9][0-9][0-9]")
	echo "Available OUTPUT resolutions:"
	echo "$RES"
	# choose the biggest supported resolution that is smaller than INPUT_RES
	ir_w=$(echo ${INPUT_RES} |cut -f 1 -d "x")
	ir_h=$(echo ${INPUT_RES} |cut -f 2 -d "x")
	for r in ${RES} ; do
		or_w=$(echo ${r} |cut -f 1 -d "x")
		or_h=$(echo ${r} |cut -f 2 -d "x")
		if [ "${or_w}" -le "${ir_w}" ] ; then
			if [ "${or_h}" -le "${ir_h}" ]; then
				OUTPUT_RES=${r}
				echo "Auto-choosing: ${r}"
				break
			fi
		fi
	done
	if [ -z ${OUTPUT_RES} ]; then
		echo
		echo "Warning: Can't find a matching output resolution"
		echo "If you are not happy with the results try to specify the resolution manually"
		echo "example: $0 <resolution>"
		echo
		OUTPUT_RES=$(xrandr |grep -A1 "^${OUTPUT}" |tail -n 1 |awk '{print $1}')
	fi
else
	OUTPUT_RES=$1
	INPUT_RES=$1
fi

echo

if [ "$1" == "-u" ]; then
	# undo (left-of: my home setup)
	INPUT_RES=$(xrandr |grep -A1 "^${INPUT}" |tail -n 1 |awk '{print $1}')
	echo "INPUT: ${INPUT} (${INPUT_RES})"
	OUTPUT_RES=$(xrandr |grep -A1 "^${OUTPUT}" |tail -n 1 |awk '{print $1}')
	echo "OUTPUT: ${OUTPUT} (${OUTPUT_RES})"
	xrandr --output ${INPUT} --auto --mode ${INPUT_RES} --output ${OUTPUT} --auto --mode ${OUTPUT_RES} --left-of ${INPUT}
else
	echo "INPUT: ${INPUT} (${INPUT_RES})"
	echo "OUTPUT: ${OUTPUT} (${OUTPUT_RES})"
	#xrandr --output ${OUTPUT} --auto --mode ${OUTPUT_RES} --same-as ${INPUT}
	#xrandr --output ${INPUT}  --auto --mode ${OUTPUT_RES} --same-as ${OUTPUT}
	xrandr --output ${OUTPUT} --auto --mode ${OUTPUT_RES} --same-as ${INPUT} --output ${INPUT} --auto --mode ${OUTPUT_RES}
fi

echo "Done!"
