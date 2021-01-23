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
    fnndsc/pl-brainmgz:         NOARGS"

    "0:1*_n:l1|
    fnndsc/pl-pfdorun:          ARGS;
                                --fileFilter=\' \';
                                --dirFilter=@SUBJID;
                                --noJobLogging; --verbose=3;
                                --exec=\'cp %inputWorkingDir/brain.mgz
                                %outputWorkingDir/brain.mgz\';
                                --previous_id=@prev_id"

    "1*_n:2*_n:l1|
    fnndsc/pl-mgz2imageslices:  ARGS;
                                --inputFile=subjects/@SUBJID/brain.mgz;
                                --outputFileStem=sample;
                                --outputFileType=png;
                                --lookupTable=__none__;
                                --skipAllLabels;
                                --saveImages;
                                --wholeVolume=entireVolume;
                                --verbosity=5;
                                --previous_id=@prev_id"

    "1*_n:3*_n:l1|
    fnndsc/pl-fastsurfer_inference: ARGS;
                                --multi=subjects;;
                                --previous_id=@prev_id"

    "3*_n:4*_n:l1|
    fnndsc/pl-mgz2imageslices:  ARGS;
                                --inputFile=@SUBJID/aparc.DKTatlas+aseg.deep.mgz;
                                --outputFileStem=sample;
                                --outputFileType=png;
                                --lookupTable=__fs__;
                                --skipAllLabels;
                                --saveImages;
                                --wholeVolume=entireVolume;
                                --verbosity=5;
                                --previous_id=@prev_id"


    "3*_n:5*_n:l1|
    fnndsc/pl-mgz2lut_report:   ARGS;
                                --file_name=@SUBJID/aparc.DKTatlas+aseg.deep.mgz;
                                --report_types=txt,html;
                                --previous_id=@prev_id"

)

WORKFLOW=\
'{

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

  fsfer.sh

SYNPOSIS

  fsfer.sh              [-C <CUBEjsonDetails>]              \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-u <user>]                         \\
                        [-w <passwd>]                       \\
                        [-G <graphvizDotFile>]              \\
                        [-i <listOfSubjectsToProcess>]      \\
                        [-s <sleepAfterPluginRun>]          \\
                        [-S]                                \\
                        [-W]                                \\
                        [-R]                                \\
                        [-J]                                \\
                        [-q]

DESC

  'fsfer1.sh' posts a workflow based off running a segmentation engine,
  ``pl-fastsurfer_inference`` and related machinery to CUBE:

                              ███:0                             pl-brainmgz
            __________________/│\_____..._______..._
         _ /     _ /     _ /   |   \_      \_        \_
        /       /       /      │      \  ...  \    ...  \
       ↓       ↓       ↓       ↓       ↓       ↓         ↓
      ███     ███     ███     ███     ███     ███       ███ :1  pl-pfdorun
      /│      /│      /│      /│      /│      /│        /│
     ↓ │     ↓ │     ↓ │     ↓ │     ↓ │     ↓ │       ↓ │
    ███│    ███│    ███│    ███│    ███│    ███│      ███│  :2  pl-mgz2imageslices
       │       │       │       │       │       │         │
       ↓       ↓       ↓       ↓       ↓       ↓         ↓
      ███     ███     ███     ███     ███     ███       ███ :3  pl-fastsurfer_inference
      /│      /│      /│      /│      /│      /│        /│
     ↓ │     ↓ │     ↓ │     ↓ │     ↓ │     ↓ │       ↓ │
    ███│    ███│    ███│    ███│    ███│    ███│      ███│  :4  pl-mgz2imageslices
       │       │       │       │       │       │         │
       ↓       ↓       ↓       ↓       ↓       ↓         ↓
      ███     ███     ███     ███     ███     ███       ███ :5  pl-mgz2lut_report

    The FS plugin, ``pl-brainmgz``, generates an output directory containing
    data from several subject brain images. This workflow will process each
    of those subjects, resulting in a fanned tree execution toplogy.

    By specifying specific subject(s) in the [-i <listOfSubjectsToProcess>],
    only those subject branches will be created, otherwise all subjects
    will be processed.

    Note, this does require some implicit knowledge since the user of
    this script would need to know which sibjects exist. By running this
    script with a ``-q``, a hard coded list of available images to process
    is printed.

ARGS

    [-s <sleepAfterPluginRun>]
    Default is '0'. Adds an explicit system ``sleep`` after executing
    a plugin. This can be useful in not overloading the ancillary
    services when large amount of plugins are being dispatched
    concurrently.

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
    boxcenter "Verify that all the plugin that constitute this workflow are    "
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
    mgzFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files
    boxcenter "Run the root node and dynamically capture a list of output    "
    boxcenter "files created by the base FS plugin. This file list will be   "
    boxcenter "processed to create the actual list of subject ids to process:"
    boxcenter "each subject id will spawn a new parallel branch.             "
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

    # Now, parse the list of files for subject ids, read into an
    # array, and print the pruned file list
    subjID=$( echo "$filesInNode"           |\
                grep mgz                    |\
                awk '{print $3}'            |\
                awk -F \/ '{print $6}')
    echo -en "\033[2A\033[2K"
    read -a a_subjID <<< $(echo $subjID)
    a_subjIDorig=("${a_subjID[@]}")
windowBottom

if (( b_imageList || b_onlyShowImageNames )) ; then
    title -d 1 "Checking that images to process exist in root pl-brainmgz..."
        boxcenter "Verify that any subject IDs explicitly listed by the user "
        boxcenter "when calling this script actually exist in the root node  "
        boxcenter "output directory space.                                   "
        boxcenter ""

        b_respSuccess=0
        b_respFail=0

        if (( b_imageList )) ; then
            read -a a_subjID <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
        fi
        for image in "${a_subjID[@]}" ; do
            opBlink_feedback "subjid to process" "::$image"  \
                             "valid-->"         "checking"
            windowBottom
            if [[ " ${a_subjIDorig[@]} " =~ " ${image} " ]] ; then
                status=0
            else
                status=1
            fi
            opRet_feedback  "$status" \
                            "subjid to process" "::$image"  \
                            "can process-->"   "valid"

        done
        postImageCheck_report
    windowBottom
    if (( b_respFail > 0 )) ;       then exit 1 ; fi
    if (( b_onlyShowImageNames )) ; then exit 0 ; fi
fi

title -d 1 "Building and Scheduling workflow..."
    boxcenter "Construct and run each branch, one per input subject id.    "
    boxcenter "If a wait condition has been specified, pause at the end of "
    boxcenter "each branch until the final compute is successful before    "
    boxcenter "buidling the next parallel branch.                          "
    boxcenter ""
    boxcenter "If a report has been specified, print a final report on the "
    boxcenter "prediction of the input image for that branch.              "
    boxcenter ""

    # Now the branch(es)
    b_respSuccess=0
    b_respFail=0
    boxcenter ""
    boxcenter ""
    for image in "${a_subjID[@]}" ; do
        echo -en "\033[2A\033[2K"
        boxcenter ""
        boxcenter "Building prediction branch for subjectimage $image..." ${LightGray}
        boxcenter ""
        boxcenter ""

        plugin_run  ":1" "a_WORKFLOWSPEC[@]" "$CUBE" ID1 $sleepAfterPluginRun\
                    "@prev_id=$ROOTID;@SUBJID=$image" && id_check $ID1

        plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 $sleepAfterPluginRun\
                    "@prev_id=$ID1;@SUBJID=$image" && id_check $ID2

        plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 $sleepAfterPluginRun\
                    "@prev_id=$ID1;@SUBJID=$image" && id_check $ID3

        plugin_run  ":4" "a_WORKFLOWSPEC[@]" "$CUBE" ID4 $sleepAfterPluginRun\
                    "@prev_id=$ID3;@SUBJID=$image" && id_check $ID3

        plugin_run  ":5" "a_WORKFLOWSPEC[@]" "$CUBE" ID5 $sleepAfterPluginRun\
                    "@prev_id=$ID3;@SUBJID=$image" && id_check $ID3

        if (( b_waitOnBranchFinish )) ; then
            waitForNodeState    "$CUBE" "finishedSuccessfully" $ID5 retState
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
