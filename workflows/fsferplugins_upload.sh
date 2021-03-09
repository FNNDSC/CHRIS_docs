#!/bin/bash
#
# Add plugins specifically for the COVIDNET feedflow.
#

./plugin_add.sh  "\
			fnndsc/pl-brainmgz,		\
			fnndsc/pl-pfdorun,		\
			fnndsc/pl-mgz2imageslices,	\
			fnndsc/pl-fastsurfer_inference,	\
			fnndsc/pl-multipass,		\
			fnndsc/pl-heatmap,		\
			fnndsc/pl-mgz2lut_report
"

#
# Adding additional users
# Users can be added using some specific variation of the
# following:
#
# CUBE USERS
# For "superusers"
#####user_add.sh -U "rudolph:rudolph1234:rudolph.pienaar@gmail.com"
# For "normal users"
#####user_add.sh    "rpienaar:rudolph1234:rppienaar@gmail.com"
#
# STORE USERS
# For "superusers"
#####user_add.sh -U -S "rudolph:rudolph1234:rudolph.pienaar@gmail.com"
# For "normal users"
#####user_add.sh -S    "rpienaar:rudolph1234:rppienaar@gmail.com"
#

