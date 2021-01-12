#!/bin/bash
#

source ./ffe.sh


# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# start feedflow specification section
# |||||||||||||||||||||||||||||||||||||
#
# The following array declares the specific containers in the workflow
# as well as the arguments to be passed to each. This is a WIP attempt
# to templatize/describe feedflow structure.
#
declare -a a_WORKFLOWSPEC=(
    "
     # Define a 'loop', a variable, and an iterator expression
     # The variable can be expanded over the iterator range
     # to create a full feed/branch structure.
     # NOTE: Obviously still WIP
    "
    "l1:_n:seq 1 5"

    "0:0|
    fnndsc/pl-lungct:           --NOARGS"

    "0:1*_n:l1|
    fnndsc/pl-med2img:          --inputFile=@image[_n];
                                --convertOnlySingleDICOM;
                                --previous_id=@prev_id"

    "1*_n:2*_n:l1|
    fnndsc/pl-covidnet:         --imagefile=sample.png;
                                --previous_id=@prev_id"

    "2*_n:3*_n:l1|
    fnndsc/pl-pdfgeneration:    --imagefile=sample.png;
                                --patientId=@patientID;
                                --previous_id=@prev_id"
)
declare -a a_PLUGINS=()
declare -a a_ARGS=()
pluginArray_filterFromWorkflow  "a_WORKFLOWSPEC[@]" "a_PLUGINS"
argArray_filterFromWorkflow     "a_WORKFLOWSPEC[@]" "a_ARGS"
a_PLUGINS=($a_PLUGINS)
a_ARGS=($a_ARGS)
# ||||||||||||||||||||||||||||||||||
# end feedflow specification section
# //////////////////////////////////


SYNOPSIS="

NAME

  covidnet.sh

SYNPOSIS

  covidnet.sh           [-C <CUBEjsonDetails>]              \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-u <user>]                         \\
                        [-w <passwd>]                       \\
                        [-G <graphvizDotFile>]              \\
                        [-i <listOfLungImagesToProcess>]    \\
                        [-W]                                \\
                        [-q]

DESC

  'covidnet.sh' posts a workflow based off COVID-NET to CUBE:

                                   ███:0          pl-lungct
                                 __/│\__
                              _ / / | \ \_
                             /   /  │  \.. \ 
                            ↓   ↓   ↓   ↓   ↓
                           ███ ███ ███ ███ ███ :1  pl-med2img
                            │   │   │   │   │
                            │   │   │   │   │
                            ↓   ↓   ↓   ↓   ↓
                           ███ ███ ███ ███ ███ :2  pl-covidnet
                            │   │   │   │   │
                            │   │   │   │   │
                            ↓   ↓   ↓   ↓   ↓
                           ███ ███ ███ ███ ███ :3  pl-pdfgeneration

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

    [-W]
    If specified, will wait at the end of a single branch for success
    of termination node before building a subsequent branch. This
    demonstrates how to script wait functionality. This logic can be
    used for simulating a delay while waiting for  a scarce computing
    resource (like a GPU) to be released for subsequent branches to
    use.

    [-G <graphvizDotFile>]
    If specified, write a graphviz .dot file that describes the workflow
    and is suitable for rendering by graphviz parsers, e.g.

                http://dreampuf.github.io/GraphvizOnline

    [-i <listOflLungImageToProcess>]
    Runs the inference pipeline of each of the comma separated images
    in the <listOfLungImagesToProcess string. Note these images *MUST*
    be valid image(s) that exists in the output of ``pl-lungct``.

    To see a list of valid images run this script with a ``-q``.

    [-q]
    Print a list of valid images and exit.

    [-r <protocol>]         (http)
    [-p <port>]             (8000)
    [-a <cubeIP>]           (%HOSTIP)
    [-u <cubeUser>]         (chris)
    [-w <cubeUserPasswd>]   (chris1234)
    A set of values to specify the details of the CUBE instance to use
    for running the workflow. Each of the above has (defaults) as shown.
    This information can also be specified by passing a JSON string with
    the [-C <CUBEjsonDetails>].

    Using one of these specific args, however, is generally simpler. Most
    often, the [-a <cubeIP>] will be used.

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

    or equivalently:

    $ ./covidnet.sh -a megalodon.local

"


PROTOCOL="http"
PORT="8000"
ADDRESS="%%HOSTIP"
USER="chris"
PASSWD="chris1234"

CUBE_FMT='{
        "protocol":     "%s",
        "port":         "%s",
        "address":      "%s",
        "user":         "%s",
        "password":     "%s"
}'

GRAPHVIZ="
digraph G {

  subgraph cluster_0 {
    style=filled;
    color=lightgrey;
    node [style=filled,color=white,fontname='mono',fontsize=8];
    %s
    label = 'ChRIS COVIDNET Feedgraph';
  }
}
"

declare -i b_respSuccess=0
declare -i b_respFail=0
declare -i STEP=0
declare -i b_imageList=0
declare -i b_onlyShowImageNames=0
declare -i b_CUBEjson=0
declare -i b_graphviz=0
declare -i b_waitOnBranchFinish=0
IMAGESTOPROCESS=""
GRAPHVIZFILE=""

while getopts "C:G:i:qxr:p:a:u:w:W" opt; do
    case $opt in
        W) b_waitOnBranchFinish=1               ;;
        C) b_CUBEjson=1
           CUBEJSON=$OPTARG                     ;;
        G) b_graphviz=1
           GRAPHVIZFILE=$OPTARG                 ;;
        i) b_imageList=1 ;
           IMAGESTOPROCESS=$OPTARG              ;;
        q) b_onlyShowImageNames=1               ;;
        r) PROTOCOL=$OPTARG                     ;;
        p) PORT=$OPTARG                         ;;
        a) ADDRESS=$OPTARG                      ;;
        u) USER=$OPTARG                         ;;
        w) PASSWD=$OPTARG                       ;;
        x) echo "$SYNOPSIS"; exit 0             ;;
        *) exit 1                               ;;
    esac
done

CUBE=$(printf "$CUBE_FMT" "$PROTOCOL" "$PORT" "$ADDRESS" "$USER" "$PASSWD")
if (( b_CUBEjson )) ; then
    CUBE="$CUBEJSON"
fi
ADDRESS=$(echo $CUBE | jq -r .address)

# Global variable that contains the "current" ID returned
# from a call to CUBE
ID="-1"

title -d 1 "Checking for plugin IDs on CUBE"                    \
            "(ids below denote plugin ids)"
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
        opBlink_feedback " $ADDRESS:$PORT " "::CUBE->$plugin" \
                         "op-->" "   search   "
        windowBottom
        RESP=$(
            chrispl-search  --for id                            \
                            --using name="$CONTAINER"           \
                            --onCUBE "$CUBE"
        )
        opRet_feedback  "$?"                                    \
                        " $ADDRESS:$PORT " "::CUBE->$plugin"    \
                        "result-->" " pid = $(echo $RESP | awk '{print $3}') "
    done
    postQuery_report
windowBottom
if (( b_respFail > 0 )) ; then exit 2 ; fi

title -d 1 "Posting root node, waiting on run, and creating a DICOM file list"
    ROOTID=-1
    retState=""
    filesInNode=""
    dcmFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files

    #\\\\\\\\\\\\\\\\\\
    # Core logic here ||
    plugin_run          "0:0"   "a_WORKFLOWSPEC[@]"   "$CUBE"  ROOTID
    waitForNodeState    "$CUBE" "finishedSuccessfully" $ROOTID retState
    filesInNode_get     "$CUBE"  $ROOTID filesInNode
    # Core logic here ||
    #///////////////////

    # Now, parse the list of files for DICOMs, read into an
    # array, and print the pruned file list
    dcmFiles=$( echo "$filesInNode"         |\
                awk '{print $3}'            |\
                awk -F \/ '{print $5}'      | grep dcm)
    echo -en "\033[2A\033[2K"
    read -a a_lungCT <<< $(echo $dcmFiles)
    a_lungCTorig=("${a_lungCT[@]}")
windowBottom

title -d 1 "Checking that images to process exist in root pl-lungct"
    b_respSuccess=0
    b_respFail=0

    if (( b_imageList )) ; then
        read -a a_lungCT <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
    fi
    for image in "${a_lungCT[@]}" ; do
        opBlink_feedback "  Image to process  " "::$image"  \
                         "valid-->"             "  checking  "
        windowBottom
        if [[ " ${a_lungCTorig[@]} " =~ " ${image} " ]] ; then
            status=0
        else
            status=1
        fi
        opRet_feedback  "$status" \
                        " Image to process "    "::$image"  \
                        "can process-->"        "   valid    "                \

    done
    postImageCheck_report
windowBottom
if (( b_respFail > 0 )) ;       then exit 1 ; fi
if (( b_onlyShowImageNames )) ; then exit 0 ; fi

title -d 1 "Building and Scheduling workflow..."
    # Now the branch(es)
    b_respSuccess=1
    b_respFail=0
    for image in "${a_lungCT[@]}" ; do

        boxcenter ""
        boxcenter "Building prediction branch for image $image..." ${Yellow}

        plugin_run  ":1" "a_WORKFLOWSPEC[@]" "$CUBE" ID1 \
                    "@prev_id=$ROOTID;@image[_n]=$image"
        plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 \
                    "@prev_id=$ID1"
        plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 \
                    "@prev_id=$ID2;@patientID=$ID3-12345"

        if (( b_waitOnBranchFinish )) ; then
            waitForNodeState    "$CUBE" "finishedSuccessfully" $ID3 retState
            echo -en "\033[2A\033[2K"
        fi

    done
    postRun_report
windowBottom
if (( b_respFail > 0 )) ; then exit 3 ; fi
