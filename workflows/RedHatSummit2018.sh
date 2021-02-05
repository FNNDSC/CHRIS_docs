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
    fnndsc/pl-mri10yr06mo01da_normal:   ARGS;
                                        --title=BrainMRI_MPC"

    "0:1|
    fnndsc/pl-freesurfer_pp:            ARGS;
                                        --ageSpec=10-06-01;
                                        --copySpec=sag,cor,tra,stats,3D,mri,surf;
                                        --title=FreeSurfer;
                                        --previous_id=@prev_id"

    "1:2*_n:l1|
    fnndsc/pl-mpcs:                     ARGS;
                                        --random;
                                        --seed=1;
                                        --posRange=3.0;
                                        --negRange=-3.0;
                                        --title=MultiPartyCompute;
                                        --previous_id=@prev_id"

    "2*_n:3*_n:l1|
    fnndsc/pl-z2labelmap:               ARGS;
                                        --imageSet=../data/set1;
                                        --negColor=B;
                                        --posColor=R;
                                        --title=RegionalHeatMap;
                                        --previous_id=@prev_id"
)

declare -a a_PLUGINS=()
declare -a a_ARGS=()
pluginArray_filterFromWorkflow  "a_WORKFLOWSPEC[@]" "a_PLUGINS"
argArray_filterFromWorkflow     "a_WORKFLOWSPEC[@]" "a_ARGS"

# ||||||||||||||||||||||||||||||||||
# end feedflow specification section
# //////////////////////////////////


SYNOPSIS="

NAME

  RedHatSummit2018.sh

SYNPOSIS

  RedHatSummit2018.sh   [-l <N>]                            \\
                        [-C <CUBEjsonDetails>]              \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-u <user>]                         \\
                        [-w <passwd>]                       \\
                        [-G <graphvizDotFile>]              \\
                        [-i <listOfLungImagesToProcess>]    \\
                        [-s <sleepAfterPluginRun>]

DESC

  'RedHatSummit2018.sh' posts a workflow to a CUBE instance that
  implements the following:

                             ⬤:0          pl-mri10yr06mo01da_normal
                             │
                             │
                             ↓
                             ⬤:1          pl-freesurfer_pp
                            ╱│╲
                           ╱ │ ╲
                          ╱  │  ╲
                         ╱   │   ╲
                        ╱    │    ╲
                       ↓     ↓     ↓
                       ⬤:2   ⬤:4   ⬤:6    pl-mpcs
                       │     │     │
                       ↓     ↓     ↓
                       ⬤:3   ⬤:5   ⬤:7    pl-z2labelmap

ARGS

    [-l <N>]
    Create <N> branches. Default is 3.

    [-s <sleepAfterPluginRun>]
    Default is '0'. Adds an explicit system ``sleep`` after executing
    a plugin. This can be useful in not overloading the ancillary
    services when large amount of plugins are being dispatched
    concurrently.

    [-S]
    If specified, save each plugin POST command on the filesystem. Useful
    for debugging.

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

        $ ./RedHatSummit2018.sh  -C '{
                   \"protocol\":     \"http\",
                   \"port\":         \"8000\",
                   \"address\":      \"megalodon.local\",
                   \"user\":         \"chris\",
                   \"password\":     \"chris1234\"
        }'

    or equivalently:

        $ ./RedHatSummit2018.sh -a megalodon.local

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
declare -i b_CUBEjson=0
declare -i b_graphviz=0
declare -i sleepAfterPluginRun=0
declare -i b_saveCalls=0
IMAGESTOPROCESS=""
GRAPHVIZFILE=""
declare -i branches=3

while getopts "C:G:l:xr:p:a:u:w:s:S" opt; do
    case $opt in
        C) b_CUBEjson=1
           CUBEJSON=$OPTARG                     ;;
        l) branches=$OPTARG                     ;;
        G) b_graphviz=1
           GRAPHVIZFILE=$OPTARG                 ;;
        S) b_saveCalls=1                        ;;
        s) sleepAfterPluginRun=$OPTARG          ;;
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

title -d 1 "Start constructing the Feed by POSTing the root FS and next nodes..."
    ROOTID=-1
    retState=""
    filesInNode=""
    dcmFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files
    boxcenter "Run the root and first nodes in series.                    "
    boxcenter ""
    windowBottom

    #\\\\\\\\\\\\\\\\\\
    # Core logic here ||
    plugin_run          "0:0"   "a_WORKFLOWSPEC[@]"   "$CUBE"  ROOTID \
                        $sleepAfterPluginRun && id_check $ROOTID
    # waitForNodeState    "$CUBE" "finishedSuccessfully" $ROOTID retState
    # dataInNode_get      fname "$CUBE"  $ROOTID filesInNode

    plugin_run          "0:1"   "a_WORKFLOWSPEC[@]"   "$CUBE"  ID1 \
                        $sleepAfterPluginRun "@prev_id=$ROOTID" && id_check $ID1
    digraph_add         "GRAPHVIZBODY"  "GRAPHVIZBODYARGS" ":0;$ROOTID" ":1;$ID1" \
                        "a_WORKFLOWSPEC[@]"
    # Core logic here ||
    #///////////////////
windowBottom

title -d 1 "Build the branching structure workflow..."
    boxcenter "Construct and run each branch, one per MPC comparison.      "
    boxcenter ""

    # Now the branch(es)
    b_respSuccess=1
    b_respFail=0
    boxcenter ""
    boxcenter ""
    for LOOP in $(seq 1 $branches); do
        echo -en "\033[2A\033[2K"
        boxcenter   ""
        boxcenter   "Building prediction branch $LOOP..." ${LightGray}
        boxcenter   ""
        boxcenter   ""
        plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 $sleepAfterPluginRun \
                    "@prev_id=$ID1" && id_check $ID2
        digraph_add "GRAPHVIZBODY"  "GRAPHVIZBODYARGS" ":1;$ID1" ":2;$ID2" \
                    "a_WORKFLOWSPEC[@]"
        plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 $sleepAfterPluginRun \
                    "@prev_id=$ID2" && id_check $ID3
        digraph_add "GRAPHVIZBODY"  "GRAPHVIZBODYARGS" ":2;$ID2" ":3;$ID3" \
                    "a_WORKFLOWSPEC[@]"
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
