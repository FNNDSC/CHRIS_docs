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

    "0:3|
    fnndsc/pl-fastsurfer_inference: ARGS;
                                --subjectDir=subjects;
                                --copyInputImage;
                                --previous_id=@prev_id"
    
    "3:4*_n:l1|
    fnndsc/pl-pfdorun:          ARGS;
                                --fileFilter=\' \';
                                --dirFilter=@mgz[_n];
                                --noJobLogging; --verbose=3;
                                --exec=\'cp %inputWorkingDir/aparc.DKTatlas+aseg.deep.mgz
                                %outputWorkingDir/aparc.DKTatlas+aseg.deep.mgz\';
                                --previous_id=@prev_id"
    "4*_n:5*_n:l1|
    fnndsc/pl-mgz2lut_report: ARGS;
                                --report_types=txt,html;
                                --file_name=@mgz[_n]/aparc.DKTatlas+aseg.deep.mgz;
                                --previous_id=@prev_id"
                                
    "4*_n:6*_n:l1|
    fnndsc/pl-mgz2imageslices:  ARGS;
                                --inputFile=@mgz[_n]/aparc.DKTatlas+aseg.deep.mgz;
                                --outputFileStem=sample;
                                --outputFileType=png;
                                --lookupTable=__fs__;
                                --skipAllLabels;
                                --saveImages;
                                --wholeVolume=entireVolume;
                                --verbosity=5;
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
  fsfer_series.sh
SYNPOSIS
  fsfer_series.sh       [-C <CUBEjsonDetails>]              \\
                        [-B1 <batchSize>]                   \\
                        [-B2 <batchSize>]                   \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-u <user>]                         \\
                        [-w <passwd>]                       \\
                        [-G <graphvizDotFile>]              \\
                        [-i <listOfLungImagesToProcess>]    \\
                        [-W]                                \\
                        [-R]                                \\
                        [-q]
DESC
  'fsfer_series.sh' posts a workflow based off GE pipeline to CUBE:
  
  
                              ███:0 pl-brainmgz
                            __/│\_____..._______...____________________
                         _ /   |   \_      \_                          \_
                        /      │      \  ...  \                          \                                      
                      ███     ███     ███     ███ :1 pl-pfdorun          ███ :3  pl-fastsurfer_inference
                       │       │       │       │                          |
                       │       │       │       │                          |
                      ███     ███     ███     ███ :2  pl-mgz2imageslices  |
      							     _______________|________________
      							    |	     |	     |   ↓   |   ↓    |  ↓     
  						           ███     ███     ███     ███     ███   :4 pl-pfdorun
 							    /│      /│      /│      /│      /│    
 						           │ |   ↓ │     ↓ │     ↓ │     ↓ │    
						          ███│    ███│    ███│    ███│    ███│   :5  pl-mgz2imageslices
							     │       │       │       │       │             
							   ███     ███     ███     ███     ███   :6  pl-mgz2lut_report


    The FS plugin, ``pl-brainmgz``, generates an output directory containing
    several candidate subjects with brain.mgz files. This workflow will process 
    each of those mgz, resulting in a fanned tree execution toplogy.
    The topography contains 2 fans that needs some throttle for consistency 
    in the entire feed. Therefore, we have introduced 2 paratmeters B1 & B2
    for the user to enter a batch size for each of the two fans. I recommend 
    a B1=10 & B2=3 that I have tested on my system of 128GB RAM.
    
ARGS
    [-G <graphvizDotFile>]
    If specified, write a graphviz .dot file that describes the workflow
    and is suitable for rendering by graphviz parsers, e.g.
                http://dreampuf.github.io/GraphvizOnline
    [-i <listOflLungImageToProcess>]
    Runs the inference pipeline of each of the comma separated images
    in the <listOfLungImagesToProcess string. Note these images *MUST*
    be valid image(s) that exists in the output of ``pl-brainmgz``.
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
    $ ./fsfer_series.sh  -C '{
               \"protocol\":     \"http\",
               \"port\":         \"8000\",
               \"address\":      \"117.local\",
               \"user\":         \"chris\",
               \"password\":     \"chris1234\"
    }'
    or equivalently:
    $ ./fsfer_series.sh -a 117.local -W
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

GRAPHVIZHEADER='digraph G {
    rankdir="LR";

    subgraph cluster_0 {
        style=filled;
        color=lightgrey;
        label = "ChRIS Parallel Segmentation Feedgraph";
        node [style=filled,fillcolor=white,fontname="mono",fontsize=5];
        edge [fontname="mono", fontsize=5];
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
        B1) batch1=$OPTARG                      ;;
        B2) batch2=$OPTARG                      ;;
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
    dcmFiles=""

    # Post the root node, wait for it to finish, and
    # collect a list of output files
    boxcenter "Run the root node and dynamically capture a list of output "
    boxcenter "files created by the base FS plugin. This file list will be"
    boxcenter "processed to create the actual list of MGZs to process -- "
    boxcenter "each MGZ will spawn a new parallel branch.               "
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
    subjID=$( echo "$filesInNode"           |\
                grep mgz                    |\
                awk '{print $3}'            |\
                awk -F \/ '{print $6}')
    echo -en "\033[2A\033[2K"
    read -a a_subjID <<< $(echo $subjID)
    a_subjIDorig=("${a_subjID[@]}")
windowBottom

if (( b_imageList || b_onlyShowImageNames )) ; then
    title -d 1 "Checking that mgz to process exist in root pl-brainmgz..."
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
    wait_count=0
    for image in "${a_subjID[@]}" ; do
        wait_count=$((wait_count+1))
        echo -en "\033[2A\033[2K"
        boxcenter ""
        boxcenter "Building prediction branch for subjectimage $image..." ${LightGray}
        boxcenter ""
        boxcenter ""

        plugin_run  ":1" "a_WORKFLOWSPEC[@]" "$CUBE" ID1 $sleepAfterPluginRun\
                    "@prev_id=$ROOTID;@SUBJID=$image" && id_check $ID1
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":0;$ROOTID" ":1;$ID1" \
                    "a_WORKFLOWSPEC[@]"

        plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 $sleepAfterPluginRun\
                    "@prev_id=$ID1;@SUBJID=$image" && id_check $ID2
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":1;$ID1" ":2;$ID2" \
                    "a_WORKFLOWSPEC[@]"
                    
        if ((wait_count==$batch1)) ; then
                    
            if (( b_waitOnBranchFinish )) ; then
                waitForNodeState    "$CUBE" "finishedSuccessfully" $ID2 retState
            fi
            wait_count=0
        fi
    done
    echo -en "\033[2A\033[2K"
    postRun_report
windowBottom

title -d 1 "Building and Scheduling workflow..."
    boxcenter "Construct and run each branch, one per input DICOM file.    "
    boxcenter "If a wait condition has been specified, pause at the end of "
    boxcenter "each branch until the final compute is successful before    "
    boxcenter "buidling the next parallel branch.                          "
    boxcenter ""
    boxcenter "If a report has been specified, print a final report on the "
    boxcenter "prediction of the input image for that branch.              "
    # Now the branch(es)
    b_respSuccess=1
    b_respFail=0
    
    
    # Run pl-fastsurfer_inference
    boxcenter ""
    boxcenter "Building prediction branch for image $image..." ${Yellow}
    boxcenter ""
    boxcenter ""
    

    plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 $sleepAfterPluginRun\
                    "@prev_id=$ROOTID" && id_check $ID3
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":0;$ROOTID" ":3;$ID3" \
                    "a_WORKFLOWSPEC[@]"
    waitForNodeState    "$CUBE" "finishedSuccessfully" $ID3 retState
    dataInNode_get      fname "$CUBE"  $ID3 filesInNode
    
    
    # Now, parse the list of files for DICOMs, read into an
    # array, and print the pruned file list
    mgzFiles=$( echo "$filesInNode"           |\
                awk -F \/ '{print $6}' | grep 10 | awk '!seen[$0]++')
    boxcenter $mgzFiles
    read -a a_segMGZ <<< $(echo $mgzFiles)
    a_segMGZorig=("${a_segMGZ[@]}")
    
    
    if (( b_imageList )) ; then
        title -d 1 "Checking that images to process exist in root pl-lungct..."
            boxcenter "Verify that any DICOMs explicitly listed by the user "
            boxcenter "when calling this script actually exist in the root  "
            boxcenter "node.                                                "
            boxcenter ""

            b_respSuccess=0
            b_respFail=0

            if (( b_imageList )) ; then
                read -a a_segMGZ <<< $(echo "$IMAGESTOPROCESS" | tr ',' ' ')
            fi
            for mgz in "${a_segMGZ[@]}" ; do
                opBlink_feedback "Image to process" "::$mgz"  \
                             "valid-->"         "checking"
                windowBottom
                if [[ " ${a_segMGZorig[@]} " =~ " ${mgz} " ]] ; then
                    status=0
                else
                    status=1
                fi
                opRet_feedback  "$status" \
                                "Image to process" "::$mgz"  \
                                "can process-->"   "valid"

            done
            postImageCheck_report
        windowBottom
        if (( b_respFail > 0 )) ;       then exit 1 ; fi
        if (( b_onlyShowImageNames )) ; then exit 0 ; fi
    fi
    
    
   

    if (( b_waitOnBranchFinish )) ; then
            waitForNodeState    "$CUBE" "finishedSuccessfully" $ID2 retState
    fi
    
    wait_count_1=0
    for mgz in "${a_segMGZ[@]}" ; do
        wait_count_1=$((wait_count_1+1))
    
        plugin_run  ":4" "a_WORKFLOWSPEC[@]" "$CUBE" ID4 $sleepAfterPluginRun\
                    "@prev_id=$ID3;@mgz[_n]=$mgz" && id_check $ID4
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":3;$ID3" ":4;$ID4" \
                    "a_WORKFLOWSPEC[@]"
        
        plugin_run  ":5" "a_WORKFLOWSPEC[@]" "$CUBE" ID5 $sleepAfterPluginRun\
                    "@prev_id=$ID4;@mgz[_n]=$mgz" && id_check $ID5
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":4;$ID4" ":5;$ID5" \
                    "a_WORKFLOWSPEC[@]"
                    
        plugin_run  ":6" "a_WORKFLOWSPEC[@]" "$CUBE" ID6 $sleepAfterPluginRun\
                    "@prev_id=$ID4;@mgz[_n]=$mgz" && id_check $ID6
        digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":4;$ID4" ":6;$ID6" \
                    "a_WORKFLOWSPEC[@]"
                    
        if ((wait_count_1==$batch2)) ; then
                    
            if (( b_waitOnBranchFinish )) ; then
                waitForNodeState    "$CUBE" "finishedSuccessfully" $ID6 retState
            fi
            wait_count_1=0
        fi
    done

   
windowBottom
if (( b_respFail > 0 )) ; then exit 3 ; fi
