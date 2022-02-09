#!/bin/bash
#

SYNOPSIS='
    NAME

        pipeline_upload.sh

    SYNOPSIS

        pipeline_upload.sh                                                      \\
                        --pipelineFile <pipelineJSONfile>                       \\
                        [-v|--verbosity <level>]                                \\
                        [-C <CUBEjsonDetails>]                                  \\
                        [-r <protocol>]                                         \\
                        [-p <port>]                                             \\
                        [-a <cubeIP>]                                           \\
                        [-u <user>]                                             \\
                        [-w <passwd>]                                           \\

        

    DESC

        "pipeline_upload.sh" is a simple shell script that uploads a JSON file
        describing a ChRIS "pipeline" (a pipeline is a directed acyclic graph
        of plugins) to a ChRIS/CUBE backend.

    ARGS

        --pipelineFile <pipelineJSONfile>
        A JSON file containing a ChRIS pipeline. For simplicity sake, the
        \"plugin_tree\" in the JSON can be specified as native JSON and does not
        need to be a JSON string.
        
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

          {
               "protocol":     "http",
               "port":         "8000",
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

        ./pipeline_upload.sh --pipelineFile covidnetpipeline.json --

    To a CUBE on 192.168.1.200:

        ./pipeline_upload.sh -a 192.168.1.200 --pipelineFile covidnetpipeline.json --


'

PROTOCOL="http"
PORT="8000"
ADDRESS="%HOSTIP"
USER="chris"
PASSWD="chris1234"

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

declare -i b_initFromJSON=0
declare -i b_noproxy=0

declare -i VERBOSITY=0


JSONFILE=defaults.json

REQUIREDFILES="jq chripon"

while :; do
    case $1 in
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
URL=${PROTOCOL}://${ADDRESS}:${PORT}
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
        if (( VERBOSITY > 0 )) ; then
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
            if [[ $neededFile == "chripon" ]] ; then
                vprint "\n\tchripon is a nodejs program. Install with\n"
                vprint "\t\tnpm install -g chripon"
                vprint "\n\tif you are using nvm, install node and friends using\n"
                vprint "\t\tnvm install v<X>.<Y>.<Z>"
            fi
            if (( ! VERBOSITY )) ; then
                printf "Some required files were not found. Run with '-v 1' for more info."
            fi
        fi
    done
}

function preamble {
    JSON=$(jo -p PACSservice=$(jo value=$PACS) listenerService=$(jo value=$LISTENER))
    echo $JSON
}

function curlH {
    echo "-H 'accept: application/json' -H 'Content-Type: application/vnd.collection+json'"
}

function CURL {
    VERB=$1
    ROUTE=$2
    JSONFILE="$3"
    NOPROXY=""
    if (( b_noproxy )) ; then
        NOPROXY="http_proxy= "
    fi
    if (( ${#JSONFILE} )) ; then
        echo "$NOPROXY curl -s -X $VERB -u ${USER}:${PASSWD} ${URL}/api/v1/$ROUTE $(curlH) -d @${JSONFILE}"
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

function pluginRegistered_check {
    local PLUGIN=$1
    local VERSION=$2
    local __status=$3
    cmd="chrispl-search --for name --using name=$PLUGIN,version=$VERSION --onCUBE '$CUBE'"
    vprint "$cmd\n" 2
    PLUGINVER=$(eval "$cmd")
    eval $__status=$?
}

function pluginRegistered_nameCheck {
    local PLUGIN=$1
    local VERSION=$2
    local __status=$3
    cmd="chrispl-search --for name --using name=$PLUGIN --onCUBE '$CUBE'"
    vprint "$cmd\n" 2
    local NAME=$(eval "$cmd")
    if (( ${#NAME} )) ; then
        eval $__status=0
    else
        eval $__status=1
    fi
}

function pluginRegistered_versionCheck {
    local PLUGIN=$1
    local VERSION=$2
    local __status=$3
    cmd="chrispl-search --for version --using name=$PLUGIN --onCUBE '$CUBE'"
    vprint "$cmd\n" 2
    local VER=$(eval "$cmd" | awk '{print $3}')
    if (( ${#VER} )) ; then
        eval $__status=0
    else
        eval $__status=1
    fi
    echo $VER
}

function pluginRegstered_handle {
    local PLUGIN=$1
    local VERSION=$2
    local __status=$3

    pluginRegistered_check $PLUGIN $VERSION status
    if (( $status )) ; then
        eprint "Some error was triggered when checking on the existence 
        of $PLUGIN (ver $VERSION) in CUBE\n"   \
        "" pass

        # Check if plugin exists
        pluginRegistered_nameCheck $PLUGIN $VERSION status
        if (( ! $status )) ; then
            eprint "Plugin $PLUGIN is registered to CUBE" "" pass
            VER=$(pluginRegistered_versionCheck $PLUGIN $VERSION status)
            eprint  "Need version\t= $VERSION"                                       \
                    "CUBE version\t= $VER"                                           \
                    3
        else
            eprint "Plugin $PLUGIN is NOT registered to CUBE"                       \
            "Please add $PLUGIN with 'plugin_add.sh' on the CUBE server"         \
            5
        fi
    else
        vprint "CUBE responds OK for $PLUGIN (ver $VERSION)."
    fi
    eval $__status=$status
}

checkDeps
if (( ${#PIPELINEFILE} )) ; then
    if [[ -f $PIPELINEFILE ]] ; then
        # There are several implicit assumptions in the structure of the JSON file
        # Ideally these should be more robustly error checked/handled.
        
        # First, read the plugin_tree array and stringify
        jsonPLUGINTREE=$(jq '.plugin_tree ' $PIPELINEFILE)
        strPLUGINTREE=$(jq '.plugin_tree | @json' $PIPELINEFILE)

        # Now, replace the plugin_tree value with its stringified equivalent
        NEWJSON=$(jq --arg tree "$strPLUGINTREE" '.plugin_tree = $tree'\
                  $PIPELINEFILE)
        PLUGINS=$(echo "$jsonPLUGINTREE" | grep plugin_name                     |\
                         awk '{print $2}' | tr -d '"' | tr -d ',' )
        VERSIONS=$(echo "$jsonPLUGINTREE" | grep plugin_version                 |\
                         awk '{print $2}' | tr -d '"' | tr -d ',' )
                         
        a_PLUGINS=($PLUGINS)
        a_VERSIONS=($VERSIONS)
        for i in "${!a_PLUGINS[@]}" ; do
            PLUGIN=${a_PLUGINS[i]}
            VERSION=${a_VERSIONS[i]}
            pluginRegstered_handle $PLUGIN $VERSION status
        done
        if (( !status )) ; then
            vprint "CUBE reports: All plugins at specified versions are registered."
        fi
    else
        eprint  \
        "\nAn error has occured!\n\tThe file [$PIPELINEFILE] was not found.\n"  \
        "Kindly verify that the correct file has been specified.\n\n"           \
        1
    fi
    POSTJSON=$(cat $PIPELINEFILE | chripon --stdin --stdout --stringify plugin_tree | tr -d "\n")
    echo "$POSTJSON" > post.json
    vprint "Payload to POST:" 1
    vprint "$POSTJSON" 1
    cmd=$(CURL POST pipelines/ post.json)
    vprint "$cmd" 1
    eval "$cmd" | jq
    rm post.json
else
    eprint      "No pipeline file was specified." \
                "Please make sure to indicate a JSON formatted file"
                2
fi

#
# _-30-_
#

