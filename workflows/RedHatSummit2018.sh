#!/bin/bash
#


declare -a a_PLUGINS=(
    "fnndsc/pl-mri10yr06mo01da_normal"
    "fnndsc/pl-freesurfer_pp"
    "fnndsc/pl-mpcs"
    "fnndsc/pl-z2labelmap"
)

SYNOPSIS="

NAME

  RedHatSummit2018.sh

SYNPOSIS

  RedHatSummit2018.sh           [-C <CUBEjsonDetails>]    \\
                                [-l <N>]

DESC

  'RedHatSummit2018.sh' posts a workflow to a CUBE instance that
  implements the following:

                             ⬤:1          pl-mri10yr06mo01da_normal
                             │
                             │
                             ↓
                             ⬤:2          pl-freesurfer_pp
                            ╱│╲
                           ╱ │ ╲
                          ╱  │  ╲
                         ╱   │   ╲
                        ╱    │    ╲
                       ↓     ↓     ↓
                       ⬤:3   ⬤:4   ⬤:5    pl-mpcs
                       │     │     │
                       ↓     ↓     ↓
                       ⬤:6   ⬤:7   ⬤:8    pl-z2labelmap

ARGS

    [-l <N>]
    Create <N> branches. Default is 3.

    [-C <CUBEjsonDetails>]

      If specified, interpret passed JSON string as the CUBE instance
      on which to schedule the run. The default is of the form:

          '{
               \"protocol\":     \"http\",
               \"port\":         \"8000\",
               \"address\":      \"%HOSTIP\",
               \"user\":         \"chris\",
               \"password\":     \"chris1234\"
          }'

      Note the single quotes about the structure. The '%HOSTIP' is a special
      construct that will be dynamically replaced by the fully qualified IP
      of the current host. This is useful in some proxied networks where the
      string 'localhost' can be problematic.

EXAMPLES

    Typical execution:

    $ ./RedHatSummit2018.sh  -C '{
               \"protocol\":     \"http\",
               \"port\":         \"8000\",
               \"address\":      \"megalodon.local\",
               \"user\":         \"chris\",
               \"password\":     \"chris1234\"
    }'

"

source ./decorate.sh
source ./cparse.sh

CUBE='{
        "protocol":     "http",
        "port":         "8000",
        "address":      "%HOSTIP",
        "user":         "chris",
        "password":     "chris1234"
}'

declare -i b_respSuccess=0
declare -i b_respFail=0
declare -i STEP=0
declare -i branches=3

while getopts "C:l:x" opt; do
    case $opt in
        C) CUBE=$OPTARG                         ;;
        l) branches=$OPTARG                     ;;
        x) echo "$SYNOPSIS"; exit 0             ;;
    esac
done

# Global variable that contains the "current" ID returned
# from a call to CUBE
ID="-1"

function queryStart_feedback {
    #
    # ARGS
    #       $1          Name of the container
    #
    # Print the starting query feedback for a given plugin search
    #
    SEARCH=$1
    printf "${LightBlueBG}${White}[ CUBE ]${NC}::${LightCyan}%-40s${Yellow}%19s${blink}${LightGreen}%-11s${NC}\n" \
        "$SEARCH" "query-->" "[searching]"                        | ./boxes.sh
}

function runStart_feedback {
    #
    # ARGS
    #       $1          Name of the container
    #
    # Print the starting query feedback for a given plugin search
    #
    RUN=$1
    printf "${LightBlueBG}${White}[ CUBE ]${NC}::${LightCyan}%-40s${Yellow}%19s${blink}${LightGreen}%-11s${NC}\n" \
        "$RUN" "  run-->" "[ posting ]"                        | ./boxes.sh
}

function successReturn_feedback {
    #
    # ARGS
    #       $1          Name of the container
    #       $2          Response from client script
    #
    # Print some useful feedback on CUBE resp success.
    #
    PLUGIN="$1"
    RESP="$2"
    ID=$(printf "%04d" $(echo "$RESP" |awk '{print $3}'))
    b_respSuccess=$(( b_respSuccess+=1 ))
    report="[ id=$ID ]"
    reportColor=LightGreen
    echo -en "\033[3A\033[2K"
    printf "${LightBlueBG}${White}[ CUBE ]${NC}::${LightCyan}%-40s${Yellow}%19s${LightGreenBG}${White}%-11s${NC}\n"     \
    "$PLUGIN" " resp-->" "$report"                            | ./boxes.sh
}

function successReturn_summary {
    #
    # Print the summary blurb on a group successful response
    #
    printf "${LightCyan}%16s${LightGreen}%-64s${NC}\n"                      \
        "$b_respSuccess"                                                    \
        " operations had a successful response"                             | ./boxes.sh
    echo ""                                                                 | ./boxes.sh
}

function failureReturn_feedback {
    #
    # ARGS
    #       $1          Name of the container
    #
    # Print some useful feedback on CUBE resp failure
    #
    PLUGIN=$1
    b_respFail=$(( b_respFail+=1 ))
    report="[ failed  ]"
    reportColor=LightRed
    echo -en "\033[3A\033[2K"
    printf "${LightBlueBG}${White}[ CUBE ]${NC}::${LightCyan}%-40s${Yellow}%19s${RedBG}${White}%-11s${NC}\n"\
    "$PLUGIN" " resp-->" "$report"                            | ./boxes.sh
}

function failureReturn_summary {
    #
    # Print the summary blurb on a group failure response
    #
    printf "${LightRed}%16s${Brown}%-64s${NC}\n"                            \
        "$b_respFail"                                                       \
    " operations had a failure response."                                   | ./boxes.sh
}

function retValue_parse {
    #
    # ARGS
    #       $1          CLI status from call
    #       $2          CLI response from call
    #       $3          Name of the container
    #
    # Parse the return value from a call to CUBE
    #
    STATUS=$1
    CLIResp=$2
    PLUGIN=$3
    if (( STATUS == 0 )) ; then
        successReturn_feedback "$PLUGIN" "$CLIResp"
    else
        failureReturn_feedback "$PLUGIN"
    fi
}

function postQuery_report {
    #
    # Print a report after the initial query has been performed.
    #
    boxcenter " "
    if (( b_respSuccess > 0 )) ; then
        successReturn_summary
    fi
    if (( b_respFail > 0 )) ; then
        failureReturn_summary
        boxcenter "The attempt to query some containers resulted in a "  ${LightRed}
        boxcenter "failure. There are many possible reasons for this  "  ${LightRed}
        boxcenter "but the first thing to verify  is that  the image  "  ${LightRed}
        boxcenter "names passed are correct.                          "  ${LightRed}
        boxcenter ""
        boxcenter "Alternatively, have the failed plugins been regi-  "  ${LightRed}
        boxcenter "stered to the CUBE instance? If not, register the  "  ${LightRed}
        boxcenter "failed plugins using                               "  ${LightRed}
        boxcenter ""
        boxcenter "plugin_add.sh <pluginContainerImage>"                 ${LightYellow}
        boxcenter ""
        boxcenter "Also, make sure that you have installed the needed "  ${LightRed}
        boxcenter "search and run CLI dependencies, 'chrispl-search'  "  ${LightRed}
        boxcenter "and 'chrispl-run' using                            "  ${LightRed}
        boxcenter ""
        boxcenter "pip install python-chrisclient"                       ${LightYellow}
        boxcenter ""
        boxcenter "This workflow will exit now with code 1."             ${Yellow}
    fi
}

function postRun_report {
    #
    # Print a report after the runs have all been schedued.
    #
    boxcenter " "
    if (( b_respSuccess > 0 )) ; then
        successReturn_summary
    fi
    if (( b_respFail > 0 )) ; then
        failureReturn_summary
        boxcenter "The attempt to schedule some containers resulted in"  ${LightRed}
        boxcenter "a failure. Please examine each container run logs  "  ${LightRed}
        boxcenter "for possible information.                          "  ${LightRed}
        boxcenter ""
        boxcenter "This workflow will exit now with code 2."             ${Yellow}
    fi
}

title -d 1 "Checking for plugin IDs on CUBE"                    \
            "ids below denote plugin ids"
    #
    # This section queries CUBE for IDs of all plugins in the plugin
    # array structure.
    #
    # If any failures were flagged, the script will exit.
    #
    b_respSuccess=0
    b_respFail=0
    for plugin in "${a_PLUGINS[@]}" ; do
        cparse $plugin "REPO" "CONTAINER" "MMN" "ENV"
        queryStart_feedback "$REPO/$CONTAINER"
        windowBottom

        RESP=$(
            chrispl-search  --for id                            \
                            --using name="$CONTAINER"           \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$RESP" "$REPO/$CONTAINER"
    done
    postQuery_report
windowBottom
if (( b_respFail > 0 )) ; then exit 1 ; fi

title -d 1 "Building and Scheduling workflow..."                \
        "ids below denote plugin instance ids"
    #
    # Build the actual workflow
    #
    b_respSuccess=0
    b_respFail=0

    # ROOTNODE -- pl-mri10yr06mo01da_normal
    # We'll pull this from the array so as not make any spelling errors
    FSPLUGIN=${a_PLUGINS[0]}
    cparse $FSPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
    runStart_feedback "$FSPLUGIN"
    windowBottom
    FSNODE=$(
            chrispl-run --plugin name=$CONTAINER                            \
                        --onCUBE "$CUBE"
    )
    retValue_parse "$?" "$FSNODE" "$FSPLUGIN"
    FSPLUGINID=$ID

    # Add the next layer, pl-freesurfer_pp, also the second container
    # in the container array, connecting it to the FSPLUGINID
    FREESURFERPLUGIN=${a_PLUGINS[1]}
    cparse $FREESURFERPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
    runStart_feedback "$FREESURFERPLUGIN"
    windowBottom
    FREESURFERNODE=$(
            chrispl-run --plugin name=$CONTAINER                            \
                        --args "--ageSpec=10-06-01;                         \
                                --copySpec=sag,cor,tra,stats,3D,mri,surf;   \
                                --previous_id=$FSPLUGINID"                  \
                        --onCUBE "$CUBE"
    )
    retValue_parse "$?" "$FREESURFERNODE" "$FREESURFERPLUGIN"
    FREESURFERID=$ID

    # Now the N pl-mpcs plugins, each connected to the
    # FREESURFERID. For ease of scripting, we'll just
    # loop N times and capture the individual IDs in an
    # array
    declare -a a_MPCSID
    MPCSPLUGIN=${a_PLUGINS[2]}
    cparse $MPCSPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
    for LOOP in $(seq 1 $branches); do
        runStart_feedback "$MPCSPLUGIN"
        windowBottom
        MPCSNODE=$(
                chrispl-run --plugin name=$CONTAINER                            \
                            --args "--random;                                   \
                                    --seed=1;                                   \
                                    --posRange=3.0;                             \
                                    --negRange=-3.0;                            \
                                    --previous_id=$FREESURFERID"                \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$MPCSNODE" "$MPCSPLUGIN"
        MPCSID=$ID
        a_MPCSID+=("$MPCSID")
    done

    # And finally, connect a pl-z2labelmap plugin to each
    # pl-mpcs in turn...
    declare -a a_Z2LABELMAP
    ZPLUGIN=${a_PLUGINS[3]}
    cparse $ZPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
    for MPCSID in "${a_MPCSID[@]}" ; do
        runStart_feedback "$ZPLUGIN"
        windowBottom
        ZNODE=$(
                chrispl-run --plugin name=$CONTAINER                            \
                            --args "--imageSet=../data/set1;                    \
                                    --negColor=B;                               \
                                    --posColor=R;                               \
                                    --previous_id=$MPCSID"                      \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$ZNODE" "$ZPLUGIN"
        ZNODEID=$ID
        a_Z2LABELMAP+=(ZNODEID)
    done
    postRun_report
windowBottom
if (( b_respFail > 0 )) ; then exit 2 ; fi
