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

    "0:0|
    fnndsc/pl-lungct:           ARGS;
                                --title=COVIDNET_lung_CT_subjects"

    "0:1*_n:l1|
    fnndsc/pl-med2img:          ARGS;
                                --inputFile=@image[_n];
                                --convertOnlySingleDICOM;
                                --title=@image[_n];
                                --previous_id=@prev_id"

    "1*_n:2*_n:l1|
    fnndsc/pl-covidnet:         ARGS;
                                --imagefile=sample.png;
                                --title=COVIDNET;
                                --previous_id=@prev_id"

    "2*_n:3*_n:l1|
    fnndsc/pl-pdfgeneration:    ARGS;
                                --imagefile=sample.png;
                                --patientId=@patientID;
                                --title=report;
                                --previous_id=@prev_id"
)

WORKFLOW=\
'{
    "WARNING":  "THIS JSON STRUCTURE IS NOT USED!!!"
    "meta": {
        "loops":    [
            {
                "l1":   {
                    "var":      "n",
                    "iterate":  [1, 5]
                }
            }
        ]
    },
    "feed": {
        "tree": [
            {
                "node_previous":    { "id": 0},
                "node_self":        { "id": 0},
                "container":        "fnndsc/pl-lungct",
                "args":             ["--NOARGS"]
            },
            {
                "node_previous":    { "id": 0},
                "node_self":        { "id": 1,  "loop": "l1" },
                "container":        "fnndsc/pl-med2img",
                "args":             [
                                        "--inputFile=@image[_n]",
                                        "--convertOnlySingleDICOM",
                                        "--previous_id=@prev_id"
                                    ]
            },
            {
                "node_previous":    { "id": 1,  "loop": "l1" },
                "node_self":        { "id": 2,  "loop": "l1" },
                "container":        "fnndsc/pl-covidnet",
                "args":             [
                                        "--imagefile=sample.png",
                                        "--previous_id=@prev_id"
                                    ]
            },
            {
                "node_previous":    { "id": 2,  "loop": "l1" },
                "node_self":        { "id": 3,  "loop": "l1" },
                "container":        "fnndsc/pl-pdfgeneration",
                "args":             [
                                        "--imagefile=sample.png",
                                        "--patientId=@patientID",
                                        "--previous_id=@prev_id"
                                    ]
            },
        ]
    }

}'

declare -a a_PLUGINS=()
declare -a a_ARGS=()
pluginArray_filterFromWorkflow  "a_WORKFLOWSPEC[@]" "a_PLUGINS"
argArray_filterFromWorkflow     "a_WORKFLOWSPEC[@]" "a_ARGS"

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
                        [-s <sleepAfterPluginRun>]          \\
                        [-W]                                \\
                        [-S]                                \\
                        [-R]                                \\
                        [-J]                                \\
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

    [-s <sleepAfterPluginRun>]
    Default is '0'. Adds an explicit system ``sleep`` after executing
    a plugin. This can be useful in not overloading the ancillary
    services when large amount of plugins are being dispatched
    concurrently.

    [-S]
    If specified, save each plugin POST command on the filesystem. Useful
    for debugging.

    [-W]
    If specified, will wait at the end of a single branch for success
    of termination node before building a subsequent branch. This
    demonstrates how to script wait functionality. This logic can be
    used for simulating a delay while waiting for  a scarce computing
    resource (like a GPU) to be released for subsequent branches to
    use.

    [-R]
    If specified, print a final one line report of the prediction for the
    image being processed on a given branch. Note that this implies a [-W].

    [-J]
    If specified, print the full JSON prediction generated by the
    pl-covidnet. Note that this implies a [-W].

    [-G <graphvizDotFile>]
    If specified, write two graphviz .dot files called

                        <graphvizDotFile>-nodes.dot
                     <graphvizDotFile>-nodes-args.dot

    that describes the workflow in graphviz format. The first dot file
    contains only the nodes in the tree, while the second contains the nodes
    with graph edges labeled with the CLI args denoting the tranition from
    one node to another.

    These dot files are suitable for rendering by graphviz parsers, e.g.

                http://dreampuf.github.io/GraphvizOnline
                http://viz-js.com


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

TIMING CONSIDERATIONS

    While this client script should ideally not concern itself with execution
    concerns beyond the logical structure of a feedflow, some notes are
    important:

        * Too many apps POSTed in quick succession *might* overwhelm the
          scheduler;

    To not overwhelm the scheduler, it is a good idea to pause for a few
    seconds after POSTing each app to the backend with a '-s 3' (for 3s
    pause) flag.

    Thus,

        $ ./covidnet.sh -a megalodon.local -s 3 -G feed

    where the '-G feed' also produces two graphviz dot files suitable for
    rendering with a graphviz viewer.

REPORTING CONSIDERATIONS

    This script can also fetch final prediction data and write a summary
    report to the console. This is set using a '-R' (report) flag. Note that
    to generate the report forces execution to run essentially in series and
    not in parallel. This is so as to print the correct report with the correct
    compute branch.

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

GRAPHVIZHEADER='digraph G {
    rankdir="LR";

    subgraph cluster_0 {
        style=filled;
        color=lightgrey;
        label = "ChRIS COVID-NET Graph";
        node [style=filled,fillcolor=white,fontname="mono",fontsize=8];
        edge [fontname="mono", fontsize=8];
'
GRAPHVIZBODY=""
GRAPHVIZBODYARGS=""

declare -i b_respSuccess=0
declare -i b_respFail=0
declare -i STEP=0
declare -i b_imageList=0
declare -i b_onlyShowImageNames=0
declare -i b_CUBEjson=0
declare -i b_graphviz=0
declare -i b_waitOnBranchFinish=0
declare -i b_printReport=0
declare -i b_printJSONprediction=0
declare -i sleepAfterPluginRun=0
declare -i b_saveCalls=0
IMAGESTOPROCESS=""
GRAPHVIZFILE=""

while getopts "C:G:i:qxr:p:a:u:w:WRJs:S" opt; do
    case $opt in
        S) b_saveCalls=1                        ;;
        s) sleepAfterPluginRun=$OPTARG          ;;
        W) b_waitOnBranchFinish=1               ;;
        R) b_waitOnBranchFinish=1
           b_printReport=1                      ;;
        J) b_waitOnBranchFinish=1
           b_printJSONprediction=1              ;;
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

title -d 1 "Checking on required dependencies..."
    boxcenter "Verify that various command line tools needed to construct this "
    boxcenter "workflow exist on the UNIX path. If any of the below files are  "
    boxcenter "not found, please install them according to the requirements of "
    boxcenter "your OS.                                                        "
    boxcenter ""
    dep_check "jq,chrispl-search,chrispl-run,http"
windowBottom
if (( b_respFail > 0 )) ; then exit 4 ; fi

title -d 1 "Checking for plugin IDs on CUBE...."                            \
            "(ids below denote plugin ids)"
    #
    # This section queries CUBE for IDs of all plugins in the plugin
    # array structure.
    #
    # If any failures were flagged, the script will exit.
    #
    b_respSuccess=0
    b_respFail=0
    boxcenter "Verify that all the plugins that constitute this workflow are    "
    boxcenter "registered to the CUBE instance with which we are communicating."
    boxcenter ""
    for plugin in "${a_PLUGINS[@]}" ; do
        cparse $plugin "REPO" "CONTAINER" "MMN" "ENV"
        opBlink_feedback "$ADDRESS:$PORT" "::CUBE->$plugin"   \
                         "op-->" "search"
        windowBottom
        RESP=$(
            chrispl-search  --for id                            \
                            --using name="$CONTAINER"           \
                            --onCUBE "$CUBE"
        )
        opRet_feedback  "$?"                                    \
                        "$ADDRESS:$PORT" "::CUBE->$plugin"    \
                        "result-->" "pid = $(echo $RESP | awk '{print $3}')"
    done
    postQuery_report
windowBottom
if (( b_respFail > 0 )) ; then exit 2 ; fi

title -d 1 "Start constructing the Feed by POSTing the root FS node..."
    ROOTID=-1
    retState=""
    filesInNode=""
    dcmFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files
    boxcenter "Run the root node and dynamically capture a list of output "
    boxcenter "files created by the base FS plugin. This file list will be"
    boxcenter "processed to create the actual list of DICOMS to process -- "
    boxcenter "each DICOM will spawn a new parallel branch.               "
    boxcenter ""
    windowBottom

    #\\\\\\\\\\\\\\\\\\
    # Core logic here ||
    plugin_run          "0:0"   "a_WORKFLOWSPEC[@]"   "$CUBE"  ROOTID \
                        $sleepAfterPluginRun && id_check $ROOTID
    waitForNodeState    "$CUBE" "finishedSuccessfully" $ROOTID retState
    dataInNode_get      fname "$CUBE"  $ROOTID filesInNode
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

if (( b_imageList )) ; then
    title -d 1 "Checking that images to process exist in root pl-lungct..."
        boxcenter "Verify that any DICOMs explicitly listed by the user "
        boxcenter "when calling this script actually exist in the root  "
        boxcenter "node.                                                "
        boxcenter ""

        b_respSuccess=0
        b_respFail=0

        if (( b_imageList )) ; then
            read -a a_lungCT <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
        fi
        for image in "${a_lungCT[@]}" ; do
            opBlink_feedback "Image to process" "::$image"  \
                             "valid-->"         "checking"
            windowBottom
            if [[ " ${a_lungCTorig[@]} " =~ " ${image} " ]] ; then
                status=0
            else
                status=1
            fi
            opRet_feedback  "$status" \
                            "Image to process" "::$image"  \
                            "can process-->"   "valid"

        done
        postImageCheck_report
    windowBottom
    if (( b_respFail > 0 )) ;       then exit 1 ; fi
    if (( b_onlyShowImageNames )) ; then exit 0 ; fi
fi

title -d 1 "Building and Scheduling workflow..."
    boxcenter "Construct and run each branch, one per input DICOM file.    "
    boxcenter "If a wait condition has been specified, pause at the end of "
    boxcenter "each branch until the final compute is successful before    "
    boxcenter "buidling the next parallel branch.                          "
    boxcenter ""
    boxcenter "If a report has been specified, print a final report on the "
    boxcenter "prediction of the input image for that branch.              "
    boxcenter ""

    # Now the branch(es)
    b_respSuccess=1
    b_respFail=0
    boxcenter ""
    boxcenter ""
    for image in "${a_lungCT[@]}" ; do
        echo -en "\033[2A\033[2K"
        boxcenter ""
        boxcenter "Building prediction branch for image $image..." ${LightGray}
        boxcenter ""
        boxcenter ""

        plugin_run  ":1" "a_WORKFLOWSPEC[@]" "$CUBE" ID1 $sleepAfterPluginRun \
                    "@prev_id=$ROOTID;@image[_n]=$image" && id_check $ID1
        digraph_add "GRAPHVIZBODY"  "GRAPHVIZBODYARGS" ":0;$ROOTID" ":1;$ID1" \
                    "a_WORKFLOWSPEC[@]"

        plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 $sleepAfterPluginRun \
                    "@prev_id=$ID1" && id_check $ID2
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":1;$ID1" ":2;$ID2" \
                    "a_WORKFLOWSPEC[@]"

        plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 $sleepAfterPluginRun \
                    "@prev_id=$ID2;@patientID=$ID1-12345" && id_check $ID3
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":2;$ID2" ":3;$ID3" \
                    "a_WORKFLOWSPEC[@]"

        if (( b_waitOnBranchFinish )) ; then
            waitForNodeState    "$CUBE" "finishedSuccessfully" $ID3 retState
        fi

        if (( b_printReport || b_printJSONprediction )) ; then
            # get list of file resources for the prediction plugin (ID2)
            dataInNode_get      file_resource "$CUBE"  $ID2 linksInNode
            echo -en "\033[2A\033[2K"
            prediction=$(echo "$linksInNode"            |\
                         grep "prediction-default.json" |\
                         awk '{print $3}')
            rm -f prediction-default.json 2>/dev/null
            http -a chris:chris1234 --quiet --download  "$prediction"
            final=$(cat prediction-default.json | jq .prediction --raw-output)
            RESULT=$(cat prediction-default.json    |\
                     sed -E 's/(.{70})/\1\n/g')
            if (( b_printJSONprediction )) ; then
                echo "$RESULT"                      | ./boxes.sh ${LightGray}
            fi
            if (( b_printReport )) ; then 
              case "$final" in
              "normal")
                    perc=$( cat prediction-default.json                     |\
                            jq .Normal --raw-output                         |\
                            xargs -i% printf 'scale=2 ; (%*10000)/100\n'    | bc)
                    boxcenter "ANALYSIS: image $image is predicted to be normal at $perc percent." ${Green}
                    ;;
                "pneumonia")
                    perc=$( cat prediction-default.json                     |\
                            jq .Pneumonia --raw-output                      |\
                            xargs -i% printf 'scale=2 ; (%*10000)/100\n'    | bc)
                    boxcenter "ANALYSIS: image $image shows pneumonia at $perc percent." ${LightPurple}
                    ;;
                "COVID-19")
                    perc=$( cat prediction-default.json                     |\
                            jq '.["COVID-19"]' --raw-output                 |\
                            xargs -i% printf 'scale=2 ; (%*10000)/100\n'    | bc)
                    boxcenter "ANALYSIS: image $image shows COVID-19 infection at $perc percent." ${Red}
                    ;;
              esac
            fi
            boxcenter ""
            boxcenter ""

            windowBottom
        fi

    done
    echo -en "\033[2A\033[2K"
    postRun_report
windowBottom
if (( b_respFail > 0 )) ; then exit 3 ; fi

if (( b_graphviz )) ; then
    graphVis_printFile "$GRAPHVIZHEADER"    \
                        "$GRAPHVIZBODY"     \
                        "$GRAPHVIZBODYARGS" \
                        "$GRAPHVIZFILE"
fi
