#!/usr/bin/env bash
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
    fnndsc/pl-dircopy:          ARGS;
                                --title=Input-Dicoms"
                                
    "0:1|
    fnndsc/pl-simpledsapp:      ARGS;
                                --title=Input-Dicoms;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"
    "1:2|
    fnndsc/pl-pfdicom_tagsub:   ARGS;
                                --extension=.dcm;
                                --tagInfo=@info;
                                --splitToken='++';
                                --splitKeyValue=',';
                                --title=Substituted-Dicoms;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"

    "1:3|
    fnndsc/pl-pfdicom_tagExtract: ARGS;
                                --extension=.dcm;
                                --outputFileType=txt,scv,json,html;
                                --outputFileStem=Pre-Sub;
                                --title=Input-Tags;
                                --imageFile=@image;
                                --imageScale=@scale;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"
                                
    "2:4|
    fnndsc/pl-pfdicom_tagExtract: ARGS;
                                --extension=.dcm;
                                --outputFileType=txt,scv,json,html;
                                --outputFileStem=Post-Sub;
                                --title=Substituted-Tags;
                                --imageFile=@image;
                                --imageScale=@scale;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"
                                
    "2:5|
    fnndsc/pl-fshack:           ARGS;
                                --inputFile='.dcm';
                                --outputFile='recon-of-SAG-anon-dcm';
                                --exec='recon-all';
                                --args=@args; 
                                --title=FreeSurfer-Results;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"


    "5:6|
    fnndsc/pl-multipass:        ARGS;
                                --splitExpr='++';
                                --commonArgs=\'--printElapsedTime --verbosity 5 --saveImages --skipAllLabels --outputFileStem sample --outputFileType png\';
                                --specificArgs=\'--inputFile recon-of-SAG-anon-dcm/mri/brainmask.mgz --wholeVolume brainVolume ++ --inputFile recon-of-SAG-anon-dcm/mri/aparc.a2009s+aseg.mgz --wholeVolume segVolume --lookupTable __fs__\';
                                --exec=pfdo_mgz2image;
                                --verbose=5;
                                --title=PNG-Images;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"

    "6:7|
    fnndsc/pl-pfdorun:          ARGS;
                                --dirFilter=label-brainVolume;
                                --fileFilter=png;
                                --verbose=5;
                                --exec=\'composite -dissolve 90 -gravity Center
                                %inputWorkingDir/%inputWorkingFile
                                %inputWorkingDir/../../aparc.a2009s+aseg.mgz/label-segVolume/%inputWorkingFile
                                -alpha Set
                                %outputWorkingDir/%inputWorkingFile\';
                                --noJobLogging;
                                --title=Overlay-PNG;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"
                                
    "5:8|
    fnndsc/pl-mgz2lut_report:   ARGS;
                                --file_name='recon-of-SAG-anon-dcm/mri/aparc.a2009s+aseg.mgz';
                                --report_types=txt,csv,json,html;
                                --title=Segmentation-Report;
                                --previous_id=@prev_id;
                                --compute_resource_name=@env"
                                                              

   

)

WORKFLOW=\
'{
        "message": "This is a WIP"
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
  Adult-Freesurfer.sh
SYNPOSIS
  Adult-Freesurfer.sh   [-C <CUBEjsonDetails>]              \\
                        [-r <protocol>]                     \\
                        [-p <port>]                         \\
                        [-a <cubeIP>]                       \\
                        [-d <upload_directory_loc>]         \\
                        [-e <compute_env>]                  \\
                        [-n <workflow_name>]                \\
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
  'Adult-Freesurfer.sh' posts a workflow based off running a FreeSurfer
  application, ``pl-fshack`` and related machinery to CUBE:
  
  TLDR;
  To run this script on a local instance of CUBE
  
  $ caw logout
  $ caw --address http://localhost:8000/api/v1/ --username 'chris' login
  $./Adult-Freesurfer.sh -a localhost -d <upload_dir> -e <compute_env> -n <workflow_name>
  
  
  
      ███                                    0:0   pl-dircopy
       │                                          (Input dicoms)
      ███                                    0:1   pl-simpledsapp
       ┼───┐                                       (Input dicoms)
       │   ↓
       │  ███                                1:3   pl-pfdicom_tagExtract
       │                                           (extract original tags)
       │ 
       ↓    
      ███                                    1:2   pl-pfdicom_tagsub
     ┌─┴─┐                                          (anonimize tags)
     ↓   │        
    ███  │                                   2:4   pl-pfdicom_tagExtract
         │                                          (extract substituted tags)
         ↓                   
        ███                                  2:5   pl-fshack
         │                                         (Run freesurfer)
         ┼───┬       
         │  ███                              5:6   pl-multipass
         │   │                                     (mgz2image)
         │   ↓ 
         │  ███                              6:7   pl-pfdorun
         │                                          (composite -dissolve)
         ↓              
        ███                                  5:8   pl-mgz2lut_report
                                                    (Report on aparc.a2009s+aseg.mgz)
 
    The user specifies the upload directory of a list of DICOMS and a 
    pl-dircopy is run as base FS plugin in this feed. 
    Note, this does require some implicit knowledge since the user of
    this script would need to know which subjects exist. By running this
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

    [-d <upload_dir>] 

    Specify the name of the upload directory in the host computer. If
    you want to upload a list of DICOMs stored in /home/name/SAG-anon ,
    then provide the name of the directory as : -d /home/name/SAG-anon.         

    [-e <compute_env>]
    By default this workflow will run on host. Suppose you have multiple
    compute env registered to your chris instance, let this script know 
    which compute environment do you want to use. specify your choice as
    : -e moc         

    [-n <name_of_workflow>]
    Specify the name of this current workflow instance by using the -n param.
    Ex. -n Adult-Freesurfer-Trial-2         

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
        $ ./Adult-Freesurfer.sh  -C '{
                   \"protocol\":     \"http\",
                   \"port\":         \"8000\",
                   \"address\":      \"117.local\",
                   \"user\":         \"chris\",
                   \"password\":     \"chris1234\"
        }'
    or equivalently:
        $ ./Adult-Freesurfer.sh -a 117.local -d <upload_dir> -e <compute_env> -n <workflow_name>

    To not overwhelm the scheduler, it is a good idea to pause for a few
    seconds after POSTing each app to the backend with a '-s 3' (for 3s
    pause) flag.
    Thus,
        $ ./Adult-Freesurfer.sh -a 117.local -d <upload_dir> -e <compute_env> -n <workflow_name> -W -s 3 -G feed
    where the '-G feed' also produces two graphviz dot files suitable for
    rendering with a graphviz viewer.
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
        label = "ChRIS FreeSurfer Study Feedgraph";
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

while getopts "C:G:i:qxr:p:a:u:d:e:n:w:WRJs:S" opt; do
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
        d) UPLOAD=$OPTARG                       ;;
        e) COMPUTE=$OPTARG                      ;;
        n) NAME=$OPTARG                         ;;
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

if [ -z $COMPUTE ]; then
    COMPUTE='host'
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
    dep_check "jq,chrispl-search,chrispl-run,http,caw"
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
    boxcenter "Upload the list of Dicoms from the user input upload dir.    "
    boxcenter "and run pl-dircopy as base FS plugin. This file list will be "
    boxcenter "processed to create the actual list of dicoms to process     "
    boxcenter "$COMPUTE"
windowBottom

    #\\\\\\\\\\\\\\\\\\
    # Core logic here ||
    
     resp=$(https -a chris:chris1234 "$(caw upload --name "$NAME" "$UPLOAD"/*)plugininstances/" accept:application/json | jq -r '.results[0].url')
    ROOTID=$(echo $resp | awk -F \/ '{print $8}')
    
    waitForNodeState    "$CUBE" "finishedSuccessfully" $ROOTID retState

    plugin_run  ":1" "a_WORKFLOWSPEC[@]" "$CUBE" ID1 $sleepAfterPluginRun \
                "@prev_id=$ROOTID;@env=$COMPUTE" && id_check $ID1
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":0;$ROOTID" ":1;$ID1"     \
                "a_WORKFLOWSPEC[@]"    
   
    plugin_run  ":2" "a_WORKFLOWSPEC[@]" "$CUBE" ID2 $sleepAfterPluginRun \
                "@prev_id=$ID1;@env=$COMPUTE;@info='PatientName,%_name|patientID_PatientName \
                                   ++ PatientID,%_md5|7_PatientID \
                                   ++ AccessionNumber,%_md5|8_AccessionNumber \
                                   ++ PatientBirthDate,%_strmsk|******01_PatientBirthDate \
                                   ++ re:.*hysician,%_md5|4_#tag \
                                   ++ re:.*stitution,#tag \
                                   ++ re:.*ddress,#tag'" && id_check $ID2
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":1;$ID1" ":2;$ID2"  \
                "a_WORKFLOWSPEC[@]"

    plugin_run  ":3" "a_WORKFLOWSPEC[@]" "$CUBE" ID3 $sleepAfterPluginRun \
                "@prev_id=$ID1;@env=$COMPUTE;@image='m:%_nospc|-_ProtocolName.jpg';@scale=3:none" && id_check $ID3
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":1;$ID1" ":3;$ID3"     \
                "a_WORKFLOWSPEC[@]"

    plugin_run  ":4" "a_WORKFLOWSPEC[@]" "$CUBE" ID4 $sleepAfterPluginRun \
                "@prev_id=$ID2;@env=$COMPUTE;@image='m:%_nospc|-_ProtocolName.jpg';@scale=3:none" && id_check $ID4
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":2;$ID2" ":4;$ID4"     \
                "a_WORKFLOWSPEC[@]"

    plugin_run  ":5" "a_WORKFLOWSPEC[@]" "$CUBE" ID5 $sleepAfterPluginRun \
                "@prev_id=$ID2;@env=$COMPUTE;@args='ARGS:-all'" && id_check $ID5
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":2;$ID2" ":5;$ID5"     \
                "a_WORKFLOWSPEC[@]"
                
    plugin_run  ":6" "a_WORKFLOWSPEC[@]" "$CUBE" ID6 $sleepAfterPluginRun \
                "@prev_id=$ID5;@env=$COMPUTE" && id_check $ID6
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":5;$ID5" ":6;$ID6"     \
                "a_WORKFLOWSPEC[@]"

    plugin_run  ":7" "a_WORKFLOWSPEC[@]" "$CUBE" ID7 $sleepAfterPluginRun \
                "@prev_id=$ID6;@env=$COMPUTE" && id_check $ID7
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":6;$ID6" ":7;$ID7"     \
                "a_WORKFLOWSPEC[@]"
                
    plugin_run  ":8" "a_WORKFLOWSPEC[@]" "$CUBE" ID8 $sleepAfterPluginRun \
                "@prev_id=$ID5;@env=$COMPUTE" && id_check $ID8
    digraph_add "GRAPHVIZBODY" "GRAPHVIZBODYARGS" ":5;$ID5" ":8;$ID8"     \
                "a_WORKFLOWSPEC[@]"
 


windowBottom
if (( b_respFail > 0 )) ; then exit 3 ; fi

if (( b_graphviz )) ; then
    graphVis_printFile "$GRAPHVIZHEADER"    \
                        "$GRAPHVIZBODY"     \
                        "$GRAPHVIZBODYARGS" \
                        "$GRAPHVIZFILE"
fi
