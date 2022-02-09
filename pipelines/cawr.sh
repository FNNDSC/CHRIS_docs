#!/bin/bash
#

SYNOPSIS='
    NAME

        cawr.sh

    SYNOPSIS

        cawr.sh                                                                 \\
                        --runPipeline <pipeline>                                \\
                        --attachToPluginIID <IID>                               \\
                        [--uploadData <upload>]                                 \\
                        [-v|--verbosity <level>]                                \\
                        [-C <CUBEjsonDetails>]                                  \\
                        [-r <protocol>]                                         \\
                        [-p <port>]                                             \\
                        [-a <cubeIP>]                                           \\
                        [-u <user>]                                             \\
                        [-w <passwd>]

    DESC

        "cawr.sh" is a simple shell script that uses "caw" to basically run a
        named pipeline off an existing plugin instance. 

        This script is probably over-engineered -- it initially started as a 
        "from first principles" application, but then pivoted to use "caw" as
        its main engine -- a move that greatly simplifying its internal logic.

        Unlike "caw" which has a somewhat "run a pipeline from a root FS node" 
        user slant, "cawr.sh" is a tad more *explicitly* generic and slanted to
        running a pipeline "from any node". This does require the user to 
        know the ID of the attachment parent plugin instance ID. Also, unlike
        "caw" which offers a more generic set of tools, "cawr.sh" is very much
        a one trick pony -- just run a pipeline.

        "caw" has a richer/better CLI and can do much more -- "cawr.sh" is just
        a crutch for one idiomatic use case of "caw". 
        
        Anything "cawr.sh" can do, "caw" can do too, except "cawr.sh" sounds like
        a low budget movie pirate.

    ARGS

        --runPipeline <pipeline>
        Required. Run/use the specified <pipeline>.

        --attachToPluginIID <IID>
        Qualified Required. Attach <pipeline> to the instance ID node of the
        target CUBE.

        [--uploadData  -- <upload>]
        If specified, push <upload> to CUBE first, and then run the target
        <pipeline> on that data. In this case, the <IID> argument is not used.
        Note the "--" argument to separate flags from <upload>.

        [--feedDesc <feedDesc>]
        [--feedName <feedName>]
        In conjunction with --uploadData, allow for descriptive additions to a 
        Feed detail.

        [-v|--verbosity <level>]
        If specified, be more chatty. Three verbosity levels exist: 1, 2, and 3.
        Each higher level provides more information.

        [--cubeJSON <cubeJSONdetails>]
        A JSON string defining the CUBE instance to use.

        [-u|--useDefaults|-d]
        If passed, read from defaults.json.

        [-j] [--json]
        If specified, show the raw JSON return of any specified operation.

        [-r <protocol>]         (http)
        [-p <port>]             (:8000)
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

          {
               "protocol":     "http",
               "port":         ":8000",
               "address":      "%HOSTIP",
               "user":         "chris",
               "password":     "chris1234"
          }

        Note the single quotes about the structure. The "%HOSTIP" is a special
        construct that will be dynamically replaced by the fully qualified IP
        of the current host. This is useful in some proxied networks where the
        string "localhost" can be problematic.



    EXAMPLES:

    Simplest case

        ./cawr.sh --runPipeline "DICOM anon" --runFromPlugin 56 --

    To a CUBE on 192.168.1.200:

        ./cawr.sh -a 192.168.1.200                                          \
                                --runPipeline "DICOM anon"                  \
                                --attachToPluginIID 56 --

    Upload <files> to a new feed and run a pipeline in that feed:

        ./cawr.sh -a 192.168.1.200                                          \
                                --runPipeline "DICOM anon"                  \
                                --upload -- <files>

'

PROTOCOL="http"
PORT=":8000"
ADDRESS="%HOSTIP"
USER="chris"
PASSWD="chris1234"

FEEDNAME="cawr upload"
FEEDDESC="This feed be made by cawr, me matey!"

CUBE_FMT='{
        "protocol":     "%s",
        "port":         "%s",
        "address":      "%s",
        "user":         "%s",
        "password":     "%s"
}'

declare -i b_initDo=0
declare -i b_JSONreport=0
declare -i b_showJSONsettings=0
declare -i b_upload=0
declare -i b_initFromJSON=0
declare -i b_noproxy=0

declare -i VERBOSITY=0


JSONFILE=defaults.json

REQUIREDFILES="jq caw"

while :; do
    case $1 in
        --runPipeline)          PIPELINE=$2                     ;;
        --attachToPluginIID)    PLUGINROOT=$2                   ;;    
        --uploadData)           b_upload=1                      ;;
        --feedDesc)             FEEDDESC="$2"                   ;;
        --feedName)             FEEDNAME="$2"                   ;;
        -h|-\?|-x|--help)
            printf "%s" "$SYNOPSIS"
            exit 1                                              ;;
        --pipelineFile)         PIPELINEFILE=$2                 ;;
        --no-proxy)             b_noproxy=1                     ;;
        -j|--json)              b_JSONreport=1                  ;;
        -v|--verbosity)         VERBOSITY=$2                    ;;
        -C)                     b_CUBEjson=1
                                CUBEJSON=$2                     ;;
        -r)                     PROTOCOL=$2                     ;;
        -p)                     PORT=$2                         ;;
        -a)                     ADDRESS=$2                      ;;
        -u)                     USER=$2                         ;;
        -w)                     PASSWD=$2                       ;;
        
        --) # End of all options
            shift
            break                                               ;;
    esac
    shift
done
listEXPR=$*

if [[ $ADDRESS == "%HOSTIP" ]] ; then
    ADDRESS=$(hostname -i)
fi

CUBE=$(printf "$CUBE_FMT" "$PROTOCOL" "$PORT" "$ADDRESS" "$USER" "$PASSWD")
URL=${PROTOCOL}://${ADDRESS}${PORT}/api/v1/
if (( b_CUBEjson )) ; then
    CUBE="$CUBEJSON"
fi

if (( b_JSONreturn )) ; then
        JSON=true
else
        JSON=false
fi

function vprint {
        MESSAGE=$1
        FILTER=$2
        LEVEL=$3
        if (( !${#LEVEL} )) ; then
            LEVEL=0
            if [[ "$FILTER" != "jq" ]] ; then
                if (( !${#FILTER} )) ; then
                    FILTER=0
                fi
                LEVEL=$FILTER
            fi
        fi
        if (( VERBOSITY > $LEVEL )) ; then
            if [[ ${FILTER} == "jq" ]] ; then
                echo -e "$MESSAGE" | jq
            else
                echo -e "$MESSAGE"
            fi
        fi
}

function eprint {
        MESSAGE=$1
        REMEDY=$2
        CODE=$3
        if [[ $CODE == "pass" ]] ; then
            ECOLOR=3
        else
            ECOLOR=1
        fi
        if (( VERBOSITY >= 0 )) ; then
                if [[ -e $(which tput) ]] ; then
                    tput setaf $ECOLOR; echo -e "$MESSAGE"
                    if (( ${#REMEDY} )) ; then
                        tput setaf 2; echo -e "$REMEDY"
                    fi
                    if [[ $CODE != "pass" ]] ; then
                        tput setaf 6; echo -n "Exiting to system with code "
                        tput setaf 3; echo -e "$CODE" ; tput setaf 7
                    fi
                else
                    echo -e "$MESSAGE"
                    if (( ${#REMEDY} )) ; then
                        echo -e "$REMEDY"
                    fi
                    if [[ $CODE != "pass" ]] ; then
                        echo -e "Exiting to system with code $CODE"
                    fi
                fi
        fi
        if [[ $CODE != "pass" ]] ; then
            exit $CODE
        fi
}

function checkDeps {
    for neededFile in $REQUIREDFILES ; do
        printf -v CHECK '%-40s' "Checking for $neededFile..."
        builtin type -P $neededFile &> /dev/null
        status=$?
        if (( ! status )) ; then
            vprint "$CHECK [ OK ]"
        else 
            vprint "$CHECK [ not found ]"
            vprint "\nPlease install this file or, if installed, make sure it is on your PATH."
            vprint "Installtion is probably distro dependent.\n"
            if [[ $neededFile == "caw" ]] ; then
                vprint "\n\tcaw is a python program. Install with\n"
                vprint "\t\tpip -U caw"
                vprint "\n\t(ideally speaking you should be in a python venv)\n"
                vprint "\t\tpython -m venv <someEnvName>"
            fi
            if (( ! VERBOSITY )) ; then
                printf "Some required files were not found. Run with '-v 1' for more info."
            fi
                eprint                                                                      \
                "\nCawr me matey!\nYar be a missin' something I need to set sail."          \
                "Squint at the ship's needs above yonder -- perhaps there be a clue."                \
                5
        fi
    done
}

function curlH {
    echo "-H 'accept: application/json' -H 'Content-Type: application/vnd.collection+json'"
}

function CURL {
    VERB=$1
    ROUTE=$2
    JSON="$3"
    NOPROXY=""
    if (( b_noproxy )) ; then
        NOPROXY="http_proxy= "
    fi
    if (( ${#JSON} )) ; then
        echo "$NOPROXY curl -s -X $VERB -u ${USER}:${PASSWD} ${URL}/api/v1/$ROUTE $(curlH) -d '"$JSON"'"
    else
        echo "$NOPROXY curl -s -X $VERB -u ${USER}:${PASSWD} ${URL}/api/v1/$ROUTE $(curlH)"
    fi
}

function evaljq {
    CMD=$1
    eval "$CMD" | jq
    if (( $? )) ; then
        MSG1="An error in parsing the command was detected."
        MSG2="This is often caused when using the command in a proxied environment."
        MSG3="Try the command again, this time using '--no-proxy'"
        if [[ -e $(which tput) ]] ; then
            tput setaf 1; echo "$MSG1"
            echo ""
            tput setaf 2; echo -e "$MSG2\n$MSG3"
        else
            echo "$MSG1"
            echo ""
            echo -e "$MSG2\n$MSG3"
        fi
    fi
}

checkDeps
if (( ${#PIPELINE} )) ; then
    if ((  ${#PLUGINROOT} || b_upload)) ; then
        ADDR="-a $URL"
        if (( b_upload )) ; then 
            CMD="caw $ADDR upload --name \"$FEEDNAME\" --description \"$FEEDDESC\"  \
                --pipeline \"$PIPELINE\" $listEXPR" 
        else
            CMD="caw $ADDR pipeline --target $PLUGINROOT \"$PIPELINE\""
        fi
        vprint "$CMD"
        eval "$CMD"
    else
        eprint                                                                      \
        "Cawr me matey!\nYa have naught said where I can sit in the tree and smoke me pipe."    \
        "Where be the place in the that thar tree I can use my pipe? Try 'cawr.sh -x'"  \
        1
    fi
else
    eprint                                                                  \
    "Cawr me matey!\nYa have narry said what pipe I should smoke! I be havin' quite a collection." \
    "Best ye be tryin' again and this time tell me what pipe ta use. Try 'cawr.sh -x'"   \
    2
fi

#
# _-30-_
#

