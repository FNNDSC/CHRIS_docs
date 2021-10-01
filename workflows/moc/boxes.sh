#!/bin/bash
#
# NAME
#
#   boxes.sh [-c] [-n] [<textColor>]
#
# ARGS
#
# [-c]
#
#	Move the cursor to the front of the line,
#	and clear the current and previous lines.
#
# [-n]
#
#	Print decorations with no color.
#
# DESC
#
#   Draws left and right "box" outlines for a string of text
#   in line by line fashion -- useful to create the "body" of
#   a box of text, for example:
#
#       │      Here is some text that          │▒
#       │      is created in a box of          │▒
#       │      some fixed width, with          │▒
#       │      a shadow effect also!           │▒
#

. ./decorate.sh
let width=80
let b_clear=0
let b_noLineColor=0

while getopts "cn" opt; do
    case $opt in
        c) b_clear=1;;
	n) b_noLineColor=1;;
	esac
done

shift "$((OPTIND-1))"

# Set the default line color
if (( $# != 1 )) ; then
	set -- ${White}
fi

# Grab the default or CLI passed color
lineColor=$1


if ((b_clear)) ; then
        echo -en "\033[2A\033[2K"
fi

while IFS= read line; do
	line="$(echo -e "${line}" | sed -e 's/[[:space:]]*$//')"
	LINELEN=${#line}
	TRAILLEN=$(( $width - $LINELEN ))
	PADDING=""
	if (( TRAILLEN > 0 )) ; then
		PADDING=$(head -c $TRAILLEN < /dev/zero | tr '\0' ' ')
	fi
	if (( ! b_noLineColor )) ; then
	    printf "${Yellow}│${lineColor}${line}${PADDING}${NC}${Yellow}│${Brown}▒${NC}\n"
	else
	    printf "│${line}${PADDING}${NC}│▒${NC}\n"
	fi
done
