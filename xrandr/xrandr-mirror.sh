#!/bin/bash
# script to mirror screen to the best available resolution on projectors
# useful for presentations, conferences, etc...
# (c) 2013 Pau Oliva Fora - @pof

#xrandr --output HDMI1 --auto --same-as eDP1
#xrandr --output HDMI1 --auto --mode 1440x900 --same-as eDP1

INPUT="eDP1"
INPUT_RES=$(xrandr  |grep " connected" |grep ${INPUT} |cut -f 3 -d " " |cut -f 1 -d "+")

OUTPUT=$(xrandr |grep " connected" |grep -v ${INPUT} |cut -f 1 -d " ")
if [ -z $1 ]; then
	OUTPUT_RES=1024x768 # default in case we can't find anything
	RES=$(xrandr |grep -A15 ${OUTPUT} |grep -B15 "connected" |awk '{print $1}' |grep "[0-9][0-9][0-9]x[0-9][0-9][0-9]")
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
else
	OUTPUT_RES=$1
fi

echo
echo "INPUT: ${INPUT} (${INPUT_RES})"

if [ "$1" == "-u" ]; then
	# undo (left-of: my home setup)
	OUTPUT_RES=$(xrandr |grep -A1 ${OUTPUT} |tail -n 1 |awk '{print $1}')
	echo "OUTPUT: ${OUTPUT} (${OUTPUT_RES})"
	xrandr --output ${OUTPUT} --auto --mode ${OUTPUT_RES} --left-of ${INPUT}
else
	echo "OUTPUT: ${OUTPUT} (${OUTPUT_RES})"
	xrandr --output ${OUTPUT} --auto --mode ${OUTPUT_RES} --same-as ${INPUT}
fi

echo "Done!"
