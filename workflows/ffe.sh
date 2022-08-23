#
# fast friendly and efficient -- ffe.sh
#
# Script that contains several "helper" type functions geared towards
# Fast Friendly visual feedback as well some Efficient control functions.
#

source ./decorate.sh
source ./cparse.sh

function dep_check {
    #
    # ARGS
    #       $1          string comma-separated list of dependencies
    #
    # DESC
    #   Checks if each dependency (i.e. program) in the passed list
    #   is existant on the current UNIX path. Silently updates the
    #   success and failure variables b_resp[Success|Fail]
    #
    local deplist=$1
    local status="checking"

    deplist=$(echo $deplist | tr ',' ' ')
    b_respSuccess=0
    b_respFail=0
    for dep in $deplist ; do
        opBlink_feedback    "dependency check "                             \
                            "::'$dep'"                                      \
                            "on path-->"                                    \
                            "checking"
        windowBottom
        type $dep 2>/dev/null >/dev/null
        status=$?
        opRet_feedback      "$status"                                       \
                            "dependency check "                             \
                            "::'$dep'"                                      \
                            "on path-->"                                    \
                            "found"
    done
    postDep_report
}

function pluginArray_filterFromWorkflow {
    #
    # ARGS
    #       $1          feedflow array to filter
    #       $2          return array
    #
    # DESC
    #   Return a string that contains only the list of
    #   plugin names from the feedflow specification
    #   array. This return can be read into an array
    #   by the caller.
    #
    local a_feedflow=("${!1}")
    local -n a_list=$2
    local PLUGIN=""
    local EL=""

    for EL in "${a_feedflow[@]}" ; do
        if [[ ${EL:0:1} == [0-9]* ]] ; then
            PLUGIN=$(
                echo "$EL" | xargs                  |\
                            awk -F\| '{print $2}'   |\
                            awk -F\: '{print $1}'
            )
            PLUGIN="${PLUGIN:1}"
            a_list+=("$PLUGIN")
        fi
    done
}

function argArray_filterFromWorkflow {
    #
    # ARGS
    #       $1          feedflow array to filter
    #
    # DESG
    #   Return a string that contains only the list of
    #   plugin names from the feedflow specification
    #   array. This return can be read into an array
    #   by the caller.
    #
    local a_feedflow=("${!1}")
    local -n a_list=$2
    local ARG=""
    local EL=""

    for EL in "${a_feedflow[@]}" ; do
        if [[ ${EL:0:1} == [0-9]* ]] ; then
            ARG=$(
                        printf "%s" "$EL" | xargs   |\
                            awk -F\| '{print $2}'   |\
                            awk -F\: '{print $2}'
            )
            ARG="${ARG:1}"
            a_list+=("$ARG")
        fi
    done
}

function pluginName_filterFromWorkflow {
    #
    # ARGS
    #       $1          feedflow array to filter
    #       $2          search term
    #       $3          return hit
    #
    # DESC
    #   Return the plugin name, filtered from the
    #   feed feedflow on the passed search term.
    #
    local a_feedflow=("${!1}")
    local search=$2
    local __ret=$3
    local PLUGIN=""
    local EL=""

    for EL in "${a_feedflow[@]}" ; do
        EL="${EL//[$'\t\r\n ']}"
        if [[ ${EL:0:1} == [0-9]* ]] ; then
            PLUGIN=$(
                echo "$EL" | xargs                  |\
                            awk -F\| '{print $2}'   |\
                            awk -F\: '{print $1}'
            )
            if [[ "$EL" == *"$search"* ]] ; then
                eval $__ret="'$PLUGIN'"
                return 0
            fi
        fi
    done
}

function criticalError_exit {
    #
    # ARGS
    #       $1          exit code
    #       $2          error message
    #
    # DESC
    #   Report a critical error and exit to shell.
    #

    local exitCode="$1"
    local errorMessage="$2"

    echo -en "\033[2A\033[2K"
    boxcenter "───────┤ ERROR ├───────" ${LightRedBG}${White}
    boxcenter "$errorMessage"           ${LightRedBG}${White}
    boxcenter ""
    boxcenter "This script will now terminate to the system with code $exitCode."   ${NC}${White}
    boxcenter ""
    windowBottom
    exit $exitCode
}

function id_check {
    #
    # ARGS
    #       $1          code returned by POSTing a plugin run
    #
    # DESC
    #   Checks the return plugin instance ID on a POST'ed job and
    #   errors out if this ID is "-1".
    #

    ID=$1
    if [[ $ID == "-1" ]] ; then
        criticalError_exit 10 \
        "The CUBE API reported a run failure on the POSTed plugin instance."
    fi
}

function waitForNodeState {
    #
    # ARGS
    #       $1          CUBE instance to query
    #       $2          desired state of plugin instance ID
    #       $3          plugin instance ID to poll
    #       $4          return state from call
    #       $5          polling interval in seconds
    #       $6          timeout in seconds
    #
    # DESC
    #   Poll a plugin instance ID and block until
    #   its return status is "finishedSuccessfully".
    #
    local CUBE=$1
    local state=$2
    local plugininstanceID=$3
    local __ret=$4
    local pollIntervalSeconds=$5
    local timeoutSeconds=$6

    local pollCount=1
    local b_poll=1
    local b_timeout=0
    local b_waitTimedOut=0
    local totalTime=0

    if (( ! ${#pollIntervalSeconds} )) ; then pollIntervalSeconds=5;    fi
    if (( ${#timeoutSeconds} )) ;        then b_timeout=1;              fi

    if [[ $plugininstanceID == "-1" ]] ; then
        criticalError_exit 10 \
        "The CUBE API reported a run failure on the POSTed plugin instance."
    fi

    boxcenter ""
    status="scheduled"
    while (( b_poll )) ; do
        echo -en "\033[3A\033[2K"
        opBlink_feedback    "$(date +%T), poll $pollCount"              \
                            "::Waiting on pinst $plugininstanceID..."   \
                            "state-->"                                  \
                            "${status}"
        search=$(
            chrispl-search  --for status                                \
                            --using id=$plugininstanceID                \
                            --across plugininstances                    \
                            --onCUBE "$CUBE"
        )
        status=$(echo $search | awk '{print $3}')
        echo -en "\033[1A\033[2K"
        opBlink_feedback    "$(date +%T), poll $pollCount"              \
                            "::Waiting on pinst $plugininstanceID..."   \
                            "state-->"                                  \
                            "${status}"
        windowBottom
        if [[ "$status" == "$state" ]] ; then break ; fi
        if (( b_timeout )) ; then
            if (( pollCount * pollIntervalSeconds < timeoutSeconds )) ; then
                b_poll=1
            else
                b_poll=0
                b_waitTimedOut=1
                status="timeout"
            fi
        fi
        sleep $pollIntervalSeconds
        ((pollCount++))
    done
    echo -en "\033[3A\033[2K"
    totalTime=$(( pollCount * pollIntervalSeconds ))
    opSolid_feedback    " $(date +%T), poll $pollCount "                \
                        "::pinst $plugininstanceID complete ($totalTime s)..." \
                        "state-->"                                      \
                        "${status}"
    windowBottom
    eval $__ret="'$status'"
}

function dataInNode_get {
    #
    # ARGS
    #       $1          fname or file_resource
    #       $2          CUBE instance to query
    #       $3          pluginInstance ID
    #       $4          file return string
    #
    # DESC
    #   Returns a string of all the files in a node.
    #
    # PRECONDITIONS
    #   Assume that pluginInstanceID has finished successfully!
    #
    local target=$1
    local CUBE=$2
    local plugininstanceID=$3
    local __ret=$4
    local query=""
    local FOR=""
    local ACROSS=""

    echo -en "\033[2A\033[2K"

    if [[ "$target" == "fname" ]] ; then
        FOR="$target"
        ACROSS="files"
    else
        FOR="$target"
        ACROSS="links"
    fi

    opBlink_feedback    "${ADDRESS}:${PORT}"                            \
                        "::Getting node data..."                        \
                        "op-->"                                         \
                        "query"
    windowBottom
    query=$(
        chrispl-search  --for "$FOR"                                    \
                        --using plugin_inst_id=$plugininstanceID        \
                        --across "$ACROSS"                              \
                        --onCUBE "$CUBE"
    )
    echo -en "\033[3A\033[2K"
    opSolid_feedback    "${ADDRESS}:${PORT}"                            \
                        "::Node data collected..."                      \
                        "result-->"                                     \
                        "$(echo "$query" | wc -l ) values"
    eval $__ret="'$query'"
    windowBottom
}

function arrayValues_doubleToSingleQuote {
    typeset -n _arr_in="$1"
    for ((i=0; i<"${#_arr_in[@]}"; i++)); do
        _arr_in[i]="${_arr_in[i]//\"/\'}"
    done
}

function array_print {
    local arr=("${!1}")
    for ((i=0; i<"${#arr[@]}"; i++)); do
        echo "$i: ${arr[$i]}"
    done
}

function a_index {
    #
    # ARGS
    #       $1          search term
    #       $2          array to search
    #
    # DESC
    #   Echo the index of the first occurrence in an array of
    #   a search term.
    #
    SEARCH=$1
    declare -a a_arr=("${!2}")
    declare i=0
    declare b_OK=0

    for i in "${!a_arr[@]}" ; do
        [[ "${a_arr[$i]}" == *"$SEARCH"* ]] && echo $i && b_OK=1 && break
    done
    if (( ! b_OK )) ; then
        echo "-1"
    fi
}

function plugin_argsSub {
    #
    # ARGS
    #       $1          plugin argument template
    #       $2          plugin argument variable substitution lookup
    #       $3          return string with substituion
    #
    # DESC
    #   Replace templatized strings (starting with '@') in the
    #   argument string with an actual value substitution.
    #
    # EXAMPLE
    #   plugin_argsSub  "--previous_id=@id;--inputFile=@file"   \
    #                   "@id=12;@file=image.jpg"                \
    #                   argSub
    #

    local argTemplate=$1
    local argLookup=$2
    local -n argSub=$3
    local IFS

    IFS=';' read -ra a_lookup <<< "$argLookup"
    for el in "${a_lookup[@]}" ; do
        IFS='='; read -r key val <<< "$el"
        argTemplate=${argTemplate//"$key"/"$val"}
    done
        # argTemplate=$(echo "$argTemplate" | tr "'" '"')
    argTemplate=$(echo "$argTemplate" | sed 's/; --/;--/g')
    argSub=$argTemplate
}

function string_flatten {
    #
    # ARGS
    #       $1          multiline string with whitespace
    #
    # DESC
    #   Returns a "flattened" version of a passed string
    #   with whitespace removed
    #
    local   str_input=$1

    echo $str_input | tr -d '\n'
}

function plugin_runFromFile {
    #
    # ARGS
    #       $1          command array to write file
    #       $2          return string from running file
    #       $3          optional if specified, dump run output to file
    #
    # DESC
    #   Due to considerable difficulties in executing a command
    #   string *within* a bash script (mostly relating to preserving)
    #   possible embedded spaces in embedded argument strings to pass
    #   down to the `chrispl-run` command, the next best solution was
    #   to construct an explicit file script, source that script from
    #   this script, and return the script output to the calling
    #   method.
    #
    typeset -n _a_cmd="$1"
    typeset -n _RUN="$2"
    local logFile="$3"
    local plugin=$(echo ${_a_cmd[2]})
    plugin=${plugin#"name="}
    file=${plugin}-$(uuidgen).sh

    argStr=${_a_cmd[4]}
    argStr=${argStr:1:-1}
    echo "chrispl-run \\" > $file
    echo -e "\t\t--plugin   ${_a_cmd[2]} \\"        >> $file
    echo -e "\t\t--args     \"$argStr\"  \\"        >> $file
    if (( ${#3} )) ; then
        echo -e "\t\t--onCUBE   '${_a_cmd[6]}' \\"  >> $file
        echo -e "\t\t${_a_cmd[7]}"                  >> $file
    else
        echo -e "\t\t--onCUBE   '${_a_cmd[6]}'"     >> $file
    fi
    _RUN=$(source $file)
    if (( ${#3} )) ; then
        echo "$_RUN" >> $file-${logFile}
    fi
    if (( ! b_saveCalls )) ; then
        rm $file
    fi
}

function graphVis_printFile {
    #
    # ARGS
    #       $1          graphviz header string
    #       $2          graphviz body with only nodes
    #       $3          graphviz body with nodes and args
    #       $4          output file stem
    #
    # DESC
    #   Create a graphviz representation of the feed, suitable
    #   for rendering by any graphviz dot file interpreter, i.e.

    local GRAPHVIZHEADER=$1
    local GRAPHVIZBODY=$2
    local GRAPHVIZBODYARGS=$3
    local GRAPHVIZFILE=$4

    echo "$GRAPHVIZHEADER" > ${GRAPHVIZFILE}-node.dot
    echo "$GRAPHVIZHEADER" > ${GRAPHVIZFILE}-node-args.dot
    echo "$GRAPHVIZBODY" >> ${GRAPHVIZFILE}-node.dot
    echo "$GRAPHVIZBODYARGS" >> ${GRAPHVIZFILE}-node-args.dot
    echo -e "    }\n}" >> ${GRAPHVIZFILE}-node.dot
    echo -e "    }\n}" >> ${GRAPHVIZFILE}-node-args.dot

}

function digraph_add {
    #
    # ARGS
    #       $1          graphviz string without edge args to edit in place
    #       $2          graphviz string with edge args to edit in place
    #       $3          (sub)string name of parent node in workflow spec
    #       $4          (sub)string name of child node in workflow spec
    #       $5          array of workflow specification
    #
    # DESC
    #   Create a graphviz representation of the feed, suitable
    #   for rendering by any graphviz dot file interpreter, i.e.
    #
    #                           viz-js.com

    local -n GRAPH="$1"
    local -n GRAPHARGS="$2"
    local parentid="$3"
    local parent=""
    local PARENT=""
    local PID=""
    local childid=$4
    local child=""
    local CHILD=""
    local CID=""
    local a_feedflow=("${!5}")
    local IFS=""
    local LABELARGS=""
    local a_plugin=()
    local a_arg=()

    IFS=";" read -r parent PID <<<$parentid
    IFS=";" read -r child CID <<<$childid
    pluginArray_filterFromWorkflow  "a_feedflow[@]" "a_plugin"
    argArray_filterFromWorkflow     "a_feedflow[@]" "a_arg"
    ppidx=$(a_index $parent "a_feedflow[@]")
    pcidx=$(a_index $child "a_feedflow[@]")
    PARENT=${a_plugin[$ppidx]}
    PARENT=$(echo "$PARENT" | awk -F\/ '{print $2}' | awk -F \- '{print $2}')
    CHILD=${a_plugin[$pcidx]}
    CHILD=$(echo "$CHILD" | awk -F\/ '{print $2}' | awk -F \- '{print $2}')
    ARGS=$(echo "${a_arg[$pcidx]}" | sed 's/;/\\l/g')
    LABELARGS="[label = \"$ARGS\"]"

    LINE="\"${PARENT}\\n${PID}\" -> \"${CHILD}\\n${CID}\";"
    LINEARGS="\"${PARENT}\\n${PID}\" -> \"${CHILD}\\n${CID}\" $LABELARGS;"

    GRAPH=$(printf "%s\n\t%s" "$GRAPH" "$LINE")
    GRAPHARGS=$(printf "%s\n\t%s" "$GRAPHARGS" "$LINEARGS")
}

function plugin_run {
    #
    # ARGS
    #       $1          (sub)string name of plugin to run
    #       $2          array of feedflow specification
    #       $3          CUBE instance details
    #       $4          return ID of plugin instance\
    #       $5          amount to sleep after after posting
    #       $6          optional arg substitution lookup
    #
    # DESC
    #   Run a plugin image with appropriate args (and substitions)
    #   with supporting logic
    #
    local SEARCH="$1"
    local a_feedflow=("${!2}")
    local CUBE="$3"
    local __ret=$4
    local sleepAfterPluginRun=$5
    local SUB="$6"

    local a_plugin=()
    local a_arg=()
    local a_cmd=()
    local pluginName=""
    local ID
    local PLUGINRUN
    local STATUSRUN
    local IFS

    echo -en "\033[2A\033[2K"
    pluginArray_filterFromWorkflow  "a_feedflow[@]" "a_plugin"
    argArray_filterFromWorkflow     "a_feedflow[@]" "a_arg"
    pidx=$(a_index $SEARCH "a_feedflow[@]")
    CUBE=$(echo $CUBE | jq -Mc )
    pluginName_filterFromWorkflow "a_feedflow[@]" "$SEARCH" "pluginName"
    if [[ "$pidx" != "-1" ]] ; then
        # pidx=$(a_index $pluginName "a_plugin[@]")
        PLUGINVER=${a_plugin[$pidx]}
        PLUGIN=$(echo $PLUGINVER | awk -F\@ '{print $1}')
        VER=$(echo $PLUGINVER | awk -F\@ '{print $2}')
        ARGS=${a_arg[$pidx]}
        if (( ${#SUB} )) ; then
            plugin_argsSub "$ARGS" "$SUB" ARGSUB
        else
            ARGSUB="$ARGS"
        fi
        cparse $PLUGIN "REPO" "CONTAINER" "MMN" "ENV"
        opBlink_feedback "$ADDRESS:$PORT" "::CUBE->$PLUGIN"             \
                         "op-->" "posting"
        windowBottom
        # Explicitly construct the command as a bash array
        a_cmd[0]="chrispl-run";     a_cmd[1]="--plugin"
                                    a_cmd[2]="name_exact=$CONTAINER,version=$VER"
                                    a_cmd[3]="--args";   a_cmd[4]="\"$ARGSUB\""
                                    a_cmd[5]="--onCUBE"; a_cmd[6]="$CUBE"
        plugin_runFromFile "a_cmd" PLUGINRUN
        ID=$(echo $PLUGINRUN | awk '{print $3}')
        if [[ $ID == "failed" ]] ; then
            STATUSRUN=1
            # if failure, rerun the plugin to capture json return
            a_cmd[7]=" --jsonReturn"
            plugin_runFromFile "a_cmd" PLUGINRUN errToFile
        else
            STATUSRUN=0
        fi
        opRet_feedback  "$STATUSRUN"                                    \
                        "$ADDRESS:$PORT" "::CUBE->$PLUGIN"              \
                        "result-->"                                     \
                        "pinst: $ID"
    else
        boxcenter "No matching plugin was found in the feedflow spec." ${Red}
        ID="-1"
    fi
    eval $__ret="'$ID'"
    windowBottom
    sleep $sleepAfterPluginRun
}

function opBlink_feedback {
    #
    # ARGS
    #       $1          left string to print
    #       $2          some description of op
    #       $3          current action
    #       $4          current action state
    #
    # Pretty print some operation in a blink state
    #
    leftID=$(center "${1:0:18}" 18)
    op=$2
    action=$3
    result=$(center "${4:0:12}" 12)

    # echo -e ''$_{1..8}'\b0123456789'
    # echo " --> $leftID <---"
    printf "\
${LightBlueBG}${White}[%*s]${NC}\
${LightCyan}%-*s\
${Yellow}%*s\
${blink}${LightGreen}[%-*s]\
${NC}\n" \
        "18" "${leftID:0:18}"       \
        "32" "${op:0:32}"           \
        "14" "${action:0:14}"       \
        "12" "${result:0:12}"       | ./boxes.sh
}

function opSolid_feedback {
    #
    # ARGS
    #       $1          left string to print
    #       $2          some description of op
    #       $3          current action
    #       $4          current action state
    #
    # Pretty print some operation in a solid state
    #
    leftID=$(center "${1:0:18}" 18)
    op=$2
    action=$3
    result=$(center "${4:0:12}" 12)

    # echo -e ''$_{1..8}'\b0123456789'
    printf "\
${LightBlueBG}${White}[%*s]${NC}\
${LightCyan}%-*s\
${Yellow}%*s\
${LightGreenBG}${White}[%-*s]\
${NC}\n" \
        "18" "${leftID:0:18}"       \
        "32" "${op:0:32}"           \
        "14" "${action:0:14}"       \
        "12" "${result:0:12}"       | ./boxes.sh
}

function opFail_feedback {
    #
    # ARGS
    #       $1          left string to print
    #       $2          some description of op
    #       $3          current action
    #       $4          current action state
    #
    # Pretty print some operation in a failed state
    #
    leftID=$(center "${1:0:18}" 18)
    op=$2
    action=$3
    result=$(center "${4:0:12}" 12)

    # echo -e ''$_{1..8}'\b0123456789'
    printf "\
${LightBlueBG}${White}[%*s]${NC}\
${LightCyan}%-*s\
${Yellow}%*s\
${LightRedBG}${White}[%-*s]\
${NC}\n" \
        "18" "${leftID:0:18}"       \
        "32" "${op:0:32}"           \
        "14" "${action:0:14}"       \
        "12" "${result:0:12}"       | ./boxes.sh
}

function successReturn_summary {
    #
    # Print the summary blurb on a group successful response
    #
    printf "${LightCyan}%16s${LightGreen}%-64s${NC}\n"                      \
        "$b_respSuccess"                                                    \
        " operation(s) had a successful response"                           | ./boxes.sh
    echo ""                                                                 | ./boxes.sh
}

function failureReturn_summary {
    #
    # Print the summary blurb on a group failure response
    #
    printf "${LightRed}%16s${Brown}%-64s${NC}\n"                            \
        "$b_respFail"                                                       \
        " operation(s) had a failure response."                             | ./boxes.sh
    echo ""                                                                 | ./boxes.sh
}

function opRet_feedback {
    #
    # ARG
    #       $1          CLI status from call
    #       $1          left blue button field text
    #       $2          left descriptive field text
    #       $4          right descriptive field text
    #       $5          right button text
    #
    # Parse the return value from a call to CUBE
    #
    STATUS=$1
    L1=$2
    L2=$3
    L3=$4
    L4=$5
    if (( STATUS == 0 )) ; then
        b_respSuccess=$(( b_respSuccess+=1 ))
        echo -en "\033[3A\033[2K"
        opSolid_feedback    "$L1" "$L2" "$L3" "$L4"
    else
        b_respFail=$(( b_respFail+=1 ))
        echo -en "\033[3A\033[2K"
        opFail_feedback  "$L1" "$L2" "$L3" "  fail  "
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
        boxcenter "This feedflow will exit now with code 1.           "  ${Yellow}
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
        boxcenter "This feedflow will exit now with code 2."             ${Yellow}
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
        boxcenter "This feedflow will exit now with code 3.           "  ${Yellow}
    fi
}

function postDep_report {
    #
    # Print a report after the dependencies have all been schedued.
    #
    boxcenter " "
    if (( b_respSuccess > 0 )) ; then
        successReturn_summary
    fi
    if (( b_respFail > 0 )) ; then
        failureReturn_summary
        boxcenter "Some required dependencies were not found in your  "  ${LightRed}
        boxcenter "shell path and are required for this script to     "  ${LightRed}
        boxcenter "correctly execute. Please manually install these   "  ${LightRed}
        boxcenter "and try again.                                     "  ${LightRed}
        boxcenter ""
        boxcenter "This feedflow will exit now with code 4.           "  ${Yellow}
    fi
}
