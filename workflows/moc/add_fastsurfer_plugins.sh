#!/bin/bash
#
# Once a ChRIS/CUBE ecosystem has been fully instantiated from a run of the
# 'make.sh' script, the system will by default only have a few test/dummy
# plugins available. This is to keep instantiation times comparatively fast,
# especially in the case of development where the whole ecosystem is created
# and destroyed multiple times.
#
# In order to add more plugins to an instantiated system, this postscript.sh
# can be used to add plugins and also provide an easy cheat sheet for adding
# more.
#

./plugin_add.sh  "\
                    ghcr.io/fnndsc/pl-pfdicom_tagsub:3.2.1,                            \
                    ghcr.io/fnndsc/pl-pfdicom_tagextract:3.1.3,                        \
                    ghcr.io/fnndsc/pl-multipass:1.2.12,                                \
                    ghcr.io/fnndsc/pl-pfdorun:2.2.6,                                   \
                    ghcr.io/fnndsc/pl-mgz2lut_report:1.3.6,                            \
                    ghcr.io/fnndsc/pl-fastsurfer_inference:1.0.17,                     \
                    ghcr.io/fnndsc/pl-simpledsapp:2.0.2,                               \
                    ghcr.io/fnndsc/pl-fshack:1.2.2,                                    \
                    fnndsc/pl-infantfs:7.1.1.1-unlicensed,                             \
                    ghcr.io/fnndsc/pl-pfdicom_tagsub:3.2.1^moc,                        \
                    ghcr.io/fnndsc/pl-pfdicom_tagextract:3.1.3^moc,                    \
                    ghcr.io/fnndsc/pl-multipass:1.2.12^moc,                            \
                    ghcr.io/fnndsc/pl-pfdorun:2.2.6^moc,                               \
                    ghcr.io/fnndsc/pl-mgz2lut_report:1.3.6^moc,                        \
                    ghcr.io/fnndsc/pl-fastsurfer_inference:1.0.17^moc,                 \
                    ghcr.io/fnndsc/pl-simpledsapp:2.0.2^moc,                           \
                    ghcr.io/fnndsc/pl-fshack:1.2.2^moc,                                \
                    fnndsc/pl-infantfs:7.1.1.1-unlicensed^moc                          \                            
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

