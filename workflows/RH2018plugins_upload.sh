#!/bin/bash
#
# Add plugins specifically for the COVIDNET feedflow.
#

./plugin_add.sh  "\
			fnndsc/pl-mri10yr06mo01da_normal,		\
			fnndsc/pl-freesurfer_pp,			\
			fnndsc/pl-mpcs,					\
			fnndsc/pl-z2labelmap
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

