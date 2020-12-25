#!/bin/bash
#


declare -a a_PLUGINS=(
    "fnndsc/pl-lungct"
    "fnndsc/pl-med2img"
    "fnndsc/pl-covidnet"
    "fnndsc/pl-pdfgeneration"
)

SYNOPSIS="

NAME

  covidnet.sh

SYNPOSIS

  covidnet.sh           [-C <CUBEjsonDetails>]              \\
                        [-i <listOfLungImagesToProcess>]    \\
                        [-q]

DESC

  'covidnet.sh' posts a workflow based off COVID-NET to CUBE:

                             ⬤:1          pl-lungct
                      ______/│\__
                     /   /   │...\
                    ↓   ↓    ↓    ↓
                   ⬤    ⬤    ⬤:2  ⬤       pl-med2img
                   │    │    │    │
                   │    │    │    │
                   ↓    ↓    ↓    ↓
                   ⬤    ⬤    ⬤:3  ⬤       pl-covidnet
                   │    │    │    │
                   │    │    │    │
                   ↓    ↓    ↓    ↓
                   ⬤    ⬤    ⬤:4  ⬤       pl-pdfgeneration

    The FS plugin, ``pl-lungct``, generates an output directory containing
    several candidate images. This workflow will process each of those
    images, resulting in a fanned tree execution toplogy.

    By specifying a specific image in the [-i <lungImageToProcess>], only
    one branch will be created.

    Note, this does require some implicit knowledge since the user of
    this script would need to know which images exist. By running this
    script with a ``-q``, a hard coded list of available images to process
    is printed.

ARGS

    [-i <listOflLungImageToProcess>]
    Runs the inference pipeline of each of the comma separated images
    in the <listOfLungImagesToProcess string. Note these images *MUST*
    be valid image(s) that exists in the output of ``pl-lungct``.

    To see a list of valid images run this script with a ``-q``.

    [-q]
    Print a list of valid images and exit.

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

    $ ./covidnet.sh  -C '{
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
declare -i b_imageList=0
declare -i b_onlyShowImageNames=0
IMAGESTOPROCESS=""

while getopts "C:i:qx" opt; do
    case $opt in
        C) CUBE=$OPTARG                         ;;
        i) b_imageList=1 ;
           IMAGESTOPROCESS=$OPTARG              ;;
        q) b_onlyShowImageNames=1               ;;
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
    ID=$(printf "%04s" $(echo "$RESP" |awk '{print $3}'))
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

function postImageCheck_report {
    #
    # Print a report after the images to process have all been checked.
    #
    boxcenter " "
    if (( b_respSuccess > 0 )) ; then
        successReturn_summary
    fi
    if (( b_respFail > 0 )) ; then
        failureReturn_summary
        boxcenter "Some images that you have chosen to process do not "  ${LightRed}
        boxcenter "exist in the base plugin that generates image      "  ${LightRed}
        boxcenter "outputs. Please only pass images that exist in the "  ${LightRed}
        boxcenter "base FS plugin.                                    "  ${LightRed}
        boxcenter ""
        boxcenter "This workflow will exit now with code 1.           "  ${Yellow}
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
        boxcenter "This workflow will exit now with code 2."             ${Yellow}
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
        boxcenter "This workflow will exit now with code 3.           "  ${Yellow}
    fi
}

declare -a a_lungCT=(
    0000.dcm
    0001.dcm
    0002.dcm
    0003.dcm
    0004.dcm
    0005.dcm
    0006.dcm
    PatientA.dcm
    PatientB.dcm
    PatientC.dcm
    PatientD.dcm
    PatientE.dcm
    PatientF.dcm
    ex-covid-ct.dcm
    ex-covid.dcm
)

a_lungCTorig=("${a_lungCT[@]}")

title -d 1 "Images available in the root pl-lungct"
    for image in "${a_lungCT[@]}" ; do
        IMAGE=$(printf "%20s" $image)
        boxcenter $IMAGE ${Yellow}
    done
windowBottom

if (( b_imageList )) ; then
    read -a a_lungCT <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
fi

title -d 1 "Images that will be processed"
    for image in "${a_lungCT[@]}" ; do
        IMAGE=$(printf "%20s" $image)
        boxcenter $IMAGE ${Yellow}
    done
windowBottom

title -d 1 "Checking that images to process exist in root pl-lungct"
    b_respSuccess=0
    b_respFail=0
    for image in "${a_lungCT[@]}" ; do
        queryStart_feedback ${image}
        windowBottom
        if [[ " ${a_lungCTorig[@]} " =~ " ${image} " ]] ; then
            status=0
        else
            status=1
        fi
        retValue_parse "$status" "check is OK" "${image}"
    done
    postImageCheck_report
windowBottom
if (( b_respFail > 0 )) ; then exit 1 ; fi

if (( b_onlyShowImageNames )) ; then
    exit 0
fi

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
if (( b_respFail > 0 )) ; then exit 2 ; fi

title -d 1 "Building and Scheduling workflow..."                \
        "ids below denote plugin instance ids"
    #
    # Build the actual workflow
    #
    b_respSuccess=0
    b_respFail=0

    # ROOTNODE -- pl-lungct
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

    # Now, we branch out and create a new branch for each element
    # in the a_lungCT array:

    for image in "${a_lungCT[@]}" ; do

        boxcenter ""
        boxcenter "Building prediction branch for image $image..."              ${Yellow}
        # Add the next layer, pl-med2img, also the second container
        # in the container array, connecting it to the FSPLUGINID
        MED2IMGPLUGIN=${a_PLUGINS[1]}
        cparse $MED2IMGPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
        runStart_feedback "$MED2IMGPLUGIN"
        windowBottom
        MED2IMGNODE=$(
                chrispl-run --plugin name=$CONTAINER                            \
                            --args "--inputFile=$image;                         \
                                    --convertOnlySingleDICOM;                   \
                                    --previous_id=$FSPLUGINID"                  \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$MED2IMGNODE" "$MED2IMGPLUGIN"
        MED2IMGID=$ID

        # Now the pl-covidnet...
        COVIDNETPLUGIN=${a_PLUGINS[2]}
        cparse $COVIDNETPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
        runStart_feedback "$COVIDNETPLUGIN"
        windowBottom
        COVIDNETNODE=$(
                chrispl-run --plugin name=$CONTAINER                            \
                            --args "--imagefile=sample.png;                     \
                                    --previous_id=$MED2IMGID"                   \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$COVIDNETNODE" "$COVIDNETPLUGIN"
        COVIDNETID=$ID

        # and finally, the pl-pdfgeneration...
        PDFGENERATIONPLUGIN=${a_PLUGINS[3]}
        cparse $PDFGENERATIONPLUGIN "REPO" "CONTAINER" "MMN" "ENV"
        runStart_feedback "$PDFGENERATIONPLUGIN"
        windowBottom
        PDFGENERATIONNODE=$(
                chrispl-run --plugin name=$CONTAINER                            \
                            --args "--imagefile=sample.png;                     \
                                    --patientId=1234567;                        \
                                    --previous_id=$COVIDNETID"                  \
                            --onCUBE "$CUBE"
        )
        retValue_parse "$?" "$PDFGENERATIONNODE" "$PDFGENERATIONPLUGIN"
        PDFGENERATIONID=$ID

    done
    postRun_report
windowBottom
if (( b_respFail > 0 )) ; then exit 3 ; fi
