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

# An alternate start to a workflow using ``pl-dircopy``.
declare -a a_WORKFLOWSPECALT=(

    "0:0|
    fnndsc/pl-dircopy:          ARGS;
                                --title=COVIDNET_Analysis_of_@image;
                                --dir=@swiftPath"

)

declare -a a_WORKFLOWSPEC=(

    "0:0|
    fnndsc/pl-lung_cnp@1.1.0:         ARGS;
                                --title=COVIDNET_lung_CT_subjects"

    "0:1:l1|
    fnndsc/pl-med2img@1.1.12:          ARGS;
                                --inputFile=@image[_n];
                                --convertOnlySingleDICOM;
                                --title=@image[_n];
                                --previous_id=@prev_id"

    "1:2:l1|
    fnndsc/pl-covidnet@0.2.3:         ARGS;
                                --imagefile=sample.png;
                                --title=COVIDNET;
                                --previous_id=@prev_id"

    "2:3:l1|
    fnndsc/pl-covidnet-pdfgeneration@0.3.0:    ARGS;
                                --imagefile=sample.png;
                                --patientId=@patientID;
                                --title=report;
                                --previous_id=@prev_id"

    "3:4:l1|
    fnndsc/pl-covidnet-meta@1.0.10:    ARGS;
                                --imagefile=sample.png;
                                --title=Meta;
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

  covidnet.sh

SYNPOSIS

  covidnet.sh           [-K]                                \\
                        [-N <email>]                        \\
                        [-F]                                \\
                        [-C <CUBEjsonDetails>]              \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-u <user>]                         \\
                        [-w <passwd>]                       \\
                        [-G <graphvizDotFile>]              \\
                        [-i <listOfLungImagesToProcess>]    \\
                        [-D <listOfAnalysisDatesForImages>] \\
                        [-s <sleepAfterPluginRun>]          \\
                        [-W]                                \\
                        [-S]                                \\
                        [-R]                                \\
                        [-J]                                \\
                        [-q]

DESC

  'covidnet.sh' posts a workflow based off COVID-NET to CUBE. It operates
  in two modes. In the first mode, the workflow runs a base plugin that
  contains all the images and analyzes them:

                                   ███:0           pl-lungct_cnp
                                 __/│\__
                              _ / / | \ \_
                             /   /  │  \.. \.
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

    The FS plugin, ``pl-lung_cp``, generates an output directory containing
    several candidate images. This workflow will process each of those
    images, resulting in a fanned tree execution toplogy.

    Alternatively, a single-feed-per-possible-image can be specifed using a
    [-F]:

                    ███  ███  ███  ███  ███  ███ ... ███ :0 pl-dircopy
                     │    │    │    │    │    │  ...  │
                     |    |    |    |    |    |  ...  |
                     │    │    │    │    │    │  ...  │
                     ↓    ↓    ↓    ↓    ↓    ↓  ...  ↓
                    ███  ███  ███  ███  ███  ███ ... ███ :1  pl-med2img
                     │    │    │    │    │    │  ...  │
                     │    │    │    │    │    │  ...  │
                     ↓    ↓    ↓    ↓    ↓    ↓  ...  ↓
                    ███  ███  ███  ███  ███  ███ ... ███ :2  pl-covidnet
                     │    │    │    │    │    │  ...  │
                     │    │    │    │    │    │  ...  │
                     ↓    ↓    ↓    ↓    ↓    ↓  ...  ↓
                    ███  ███  ███  ███  ███  ███ ... ███ :3  pl-pdfgeneration


    By specifying a specific image set in the [-i <listOfLungImagesToProcess>],
    only those specific images will be processed.

    Note, this does require some implicit knowledge since the user of
    this script would need to know which images exist. By running this
    script with a ``-q``, a hard coded list of available images to process
    is printed.

ARGS

    [-K]
    Skip the ``pl-lung_cnp`` node. In the Feed generation case, the default
    operation is to create a ``pl-lung_cnp`` node and capture a list of the
    node contents. The elements of this list are compared with any in the
    [-i <imageList>] to provide an added sanity check (basically check that
    the image specified in the CLI is in a valid image of the ``pl-lung_cnp``
    plugin). To skip this test (usually indicated in the -F case), use a
    '-K'.

    [-N <email>]
    If specified, _create_ a new user on CUBE using the <user>:<passwd> and
    with email <email>.

    [-F]
    If specified, create a new Feed top level feed using ``pl-dircopy`` off
    an explicit DICOM filename. The DICOM filename is passed with a spec
    [-i <fname>].

    [-i <listOflLungImageToProcess>]
    Runs the inference pipeline of each of the comma separated images
    in the <listOfLungImagesToProcess string. Note these images *MUST*
    be valid image(s) that exists in the output of ``pl-lungct``.

    To see a list of valid images run this script with a ``-q``.

    [-D <listOfDateStringsPerImage>]
    If specified, then for each image in [-i <imageList>] read a corresponding
    date string from this comma separated list and use that date as the time-
    stamp for the analysis.

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

declare -i b_skipFScheck=0
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
declare -i b_newUserCreate=0
declare -i b_createUIFeed=0
declare -i b_useAnalysisDates
IMAGESTOPROCESS=""
ANALYSISDATES=""
GRAPHVIZFILE=""

while getopts "KN:FC:G:i:D:qxr:p:a:u:w:WRJs:S" opt; do
    case $opt in
        K) b_skipFScheck=1                      ;;
        N) b_newUserCreate=1
           EMAIL=$OPTARG                        ;;
        F) b_createUIFeed=1                     ;;
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
        D) b_useAnalysisDates=1 ;
           ANALYSISDATES=$OPTARG                ;;
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

if (( b_newUserCreate )) ; then
    title -d 1 "Create a new user on CUBE"
        boxcenter "Create a new user with name:password = $USER:$PASSWD "
        boxcenter ""

        CMD="http POST $PROTOCOL://$ADDRESS:$PORT/api/v1/users/ \
            Content-Type:application/vnd.collection+json \
            Accept:application/vnd.collection+json \
            template:='{
                \"data\":[{\"name\":\"email\",\"value\":\"$EMAIL\"},
                          {\"name\":\"password\",\"value\":\"$PASSWD\"},
                          {\"name\":\"username\",\"value\":\"$USER\"}]
            }'"
        RES=$(eval "$CMD")
        ERR=$(echo $RES | grep error | wc -l)
        echo "$RES" | jq | sed -E 's/(.{80})/\1\n/g' | ./boxes.sh ${LightGreen}
        if (( ERR )) ; then
            boxcenter ""
            boxcenter "Some error has occured in the user creation!" ${LightRed}
            boxcenter ""
            windowBottom
            exit 1
        fi
    windowBottom
fi

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
    for plugin_ver in "${a_PLUGINS[@]}" ; do
        plugin=$(echo $plugin_ver | awk -F\@ '{print $1}')
        version=$(echo $plugin_ver | awk -F\@ '{print $2}')
        cparse $plugin "REPO" "CONTAINER" "MMN" "ENV"
        opBlink_feedback "$ADDRESS:$PORT" "::CUBE->$plugin"     \
                         "op-->" "search"
        windowBottom
        RESP=$(
            chrispl-search  --for id                                          \
                            --using name_exact="$CONTAINER",version="$version"\
                            --onCUBE "$CUBE"
        )
        opRet_feedback  "$?"                                    \
                        "$ADDRESS:$PORT" "::CUBE->$plugin"      \
                        "result-->" "pid = $(echo $RESP | awk '{print $3}')"
    done
    postQuery_report
windowBottom
if (( b_respFail > 0 )) ; then exit 2 ; fi

if (( ! b_skipFScheck )) ; then
  title -d 1 "Start constructing the Feed by POSTing the root FS node..."
    ROOTID=-1
    retState=""
    filesInNode=""
    dcmFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files
    boxcenter "Run the root node and dynamically capture a list of output  "
    boxcenter "files created by the base FS plugin. This file list will be "
    boxcenter "processed to create the actual list of DICOMS to process -- "
    boxcenter "each DICOM will spawn a new parallel branch.                "
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
fi

if (( b_imageList )) ; then
    read -a a_lungCT <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
fi

if (( b_useAnalysisDates )) ; then
    IFS=',' read -ra a_analysisDate <<< $(echo "$ANALYSISDATES")
fi

if (( b_imageList && ! b_skipFScheck )) ; then
    title -d 1 "Checking that images to process exist in root pl-lung_cnp..."
        boxcenter "Cross reference that any DICOMs explicitly listed by the "
        boxcenter "user when calling this script with DICOMS that are of the"
        boxcenter "payload in pl-lung_cnp.                                  "
        boxcenter ""

        b_respSuccess=0
        b_respFail=0

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
    boxcenter "If a per feed has been indicated, then create a new feed FS "
    boxcenter "for each image, and process subsequently                    "
    boxcenter ""

    # Now the branch(es)
    b_respSuccess=1
    b_respFail=0
    boxcenter ""
    boxcenter ""
    idx=0
    for image in "${a_lungCT[@]}" ; do
        echo -en "\033[2A\033[2K"
        boxcenter ""
        boxcenter "Building prediction branch for image $image..." ${LightGray}
        boxcenter ""
        boxcenter ""

        if (( b_createUIFeed )) ; then
            #
            # Determining the MRN from the DICOM image name is a bit
            # idiosyncratic.
            #
            # The assumption of naming is:
            #
            #   <MRN>[_XX_YY].dcm
            #
            MRN=$(basename $image .dcm | awk -F \_ '{print $1}')
            SWIFTFULLPATH=$(http -a chris:chris1234                             \
                GET ${PROTOCOL}://${ADDRESS}:${PORT}/api/v1/pacsfiles/search/   \
                PatientID=="$MRN"                                               |\
                jq '.collection.items | .[] | .data | .[] | .value'             | grep PACS
            )
            # Read all the possible path hits into an array...
            a_SWIFTPATH=($SWIFTFULLPATH)
            # ... and find the index of the $image in this array
            sidx=$(a_index $image "a_SWIFTPATH[@]")
            SWIFTPATH=$(echo "$SWIFTFULLPATH" | tr ' ' '\n' | grep $image)
            if (( ! ${#SWIFTPATH} )) ; then
                boxcenter   "The swift path had zero length. This means that the DICOM" ${Cyan}
                boxcenter   "file does not seem to be registered to the PACS/SERVICES " ${Cyan}
                boxcenter   "handler.                                                 " ${Cyan}
                boxcenter   ""
                boxcenter   "Skipping this image." ${LightPurple}
                windowBottom
                continue
            fi
            l_keys=$(http -a chris:chris1234                                    \
                GET ${PROTOCOL}://${ADDRESS}:${PORT}/api/v1/pacsfiles/search/   \
                PatientID=="$MRN"                                               |\
                jq '.collection.items  | .['$sidx'] | .data | .[] | .name' | tr '\n' '|'
            )
            l_keys=${l_keys::-1}
            l_keys="${l_keys//\"/}"
            l_value=$(http -a chris:chris1234                                    \
                GET ${PROTOCOL}://${ADDRESS}:${PORT}/api/v1/pacsfiles/search/   \
                PatientID=="$MRN"                                               |\
                jq '.collection.items  | .['$sidx'] | .data | .[] | .value' | tr '\n' '|'
            )
            l_value=${l_value::-1}
            l_value="${l_value//\"/}"
            s=$(printf "%s\n%s" "$l_keys" "$l_value")
            JSONquery=$(
                jq -Rn '
                    ( input  | split("|") ) as $keys |
                    ( inputs | split("|") ) as $vals |
                    [[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
                    ' <<<"$s" | tr -d '[:space:]'
            )
            # Extract the 'creation_date' and convert to timestamp:
            CREATIONDATE=$(echo $JSONquery | jq '.creation_date')
            CREATIONDATE="${CREATIONDATE//\"/}"
            if (( b_useAnalysisDates )) ; then
                CREATIONDATE=${a_analysisDate[$idx]}
            fi
            TIMESTAMP=$(date -d "$CREATIONDATE" +"%s%3N")
            JSONcontents=$(
                jq --arg key0 'timestamp' --arg value0 $TIMESTAMP           \
                   --arg key1 'img'       --arg value1 "$JSONquery"         \
                   '. | .[$key0]=$value0 | .[$key1]=$value1' <<< '{}'       |\
                tr -d '[:space:]'
            )
            # remove the stringify formatting that jq added...
            JSONcontents=$(echo "$JSONcontents" | sed 's/\\//g')
            # and now put it back!
            JSONcontents=${JSONcontents//\"/\\\"}
            # and some more fudging...
            JSONcontents=$(echo $JSONcontents | sed 's/\\"{/{/' | sed 's/}\\"}/}}/')
            JSONcontents=$(echo "$JSONcontents"                         |\
                            sed 's/tamp\\\":\\\"/tamp\\":/'             |\
                            sed 's/\\\",\\\"img/,\\\"img/'              |\
                            sed 's/id\\\":\\\"/id\\":/'                 |\
                            sed 's/\\\",\\\"creation/,\\\"creation/'    |\
                            sed 's/PatientAge\\\":\\\"/PatientAge\\":/' |\
                            sed 's/\\\",\\\"PatientSex/,\\\"PatientSex/'
            )
            plugin_run  "0:0" "a_WORKFLOWSPECALT[@]" "$CUBE" ROOTID         \
                        $sleepAfterPluginRun                                \
                        "@image=$MRN;@swiftPath=$SWIFTPATH" && id_check $ROOTID

            # Determine the Feed ID from the instance ID:
            echo -en "\033[2A\033[2K"
            FEEDID=$(
                chrispl-search  --for feed_id --using id=$ROOTID --across plugininstances \
                                --onCUBE "$CUBE" | awk '{print $3}'
            )
            boxcenter   "Feed ID: ${FEEDID}" ${Cyan}
            # Get the note URL:
            NOTEURL=$(
                http -a ${USER}:${PASSWD} GET                           \
                ${PROTOCOL}://${ADDRESS}:${PORT}/api/v1/${FEEDID}/      |\
                jq  '.collection.items | . [] | .links | .[] | .href'   |\
                grep note
            )
            boxcenter   "Edit (PUT) title/content to note URL:"
            boxcenter   "${NOTEURL}"
            # Set the note information:
            CMD="
                http -a ${USER}:${PASSWD} PUT                           \
                ${NOTEURL}                                              \
                Content-Type:application/vnd.collection+json            \
                Accept:application/vnd.collection+json                  \
                template:='{
                    \"data\":[
                        {\"name\":\"title\",    \"value\":\"COVIDNET_ANALYSIS_NOTE\"},
                        {\"name\":\"content\",  \"value\":\"${JSONcontents}\"}
                    ]
                }'
            "
            # echo "$CMD"
            RES=$(eval "$CMD")
            ERR=$(echo $RES | grep error | wc -l)
            # echo "$RES" | jq | sed -E 's/(.{80})/\1\n/g' | ./boxes.sh ${LightGreen}
            echo "$RES" | jq | fold -w 75 | ./boxes.sh ${LightGreen}
            if (( ERR )) ; then
                boxcenter ""
                boxcenter "Some error has occured in the user creation!" ${LightRed}
                boxcenter ""
                windowBottom
                exit 1
            fi
            windowBottom
        fi

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

        plugin_run  ":4" "a_WORKFLOWSPEC[@]" "$CUBE" ID4 $sleepAfterPluginRun \
                    "@prev_id=$ID3" && id_check $ID4
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":3;$ID3" ":4;$ID4" \
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
        ((idx=idx+1))
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
