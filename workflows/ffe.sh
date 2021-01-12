#
# fast friendly and efficient -- ffe.sh
#
# Script that contains several "helper" type functions geared towards
# Fast Friendly visual feedback as well some Efficient control functions.
#

source ./decorate.sh
source ./cparse.sh

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
    local __ret=$2
    local a_list=()

    for EL in "${a_feedflow[@]}" ; do
        EL="${EL//[$'\t\r\n ']}"
        if [[ ${EL:0:1} == [0-9]* ]] ; then
            PLUGIN=$(
                echo "$EL" | xargs                  |\
                            awk -F\| '{print $2}'   |\
                            awk -F\: '{print $1}'
            )
            a_list+=("$PLUGIN")
        fi
    done
    str_array="${a_list[@]}"
    eval $__ret="'$str_array'"
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
    local b_notimeout=0
    local totalTime=0

    if (( ! ${#pollIntervalSeconds} )) ; then
        pollIntervalSeconds=5
    fi
    if (( ! ${#timeoutSeconds} )) ; then
        b_notimeout=1
    fi

    boxcenter ""
    windowBottom
    status="scheduled"
    while (( b_poll )) ; do
        echo -en "\033[3A\033[2K"
        opBlink_feedback    " $(date +%T), poll $pollCount "            \
                            "::Waiting on pinst $plugininstanceID..."   \
                            "state-->"                                  \
                            "  ${status}"
        search=$(
            chrispl-search  --for status                                \
                            --using id=$plugininstanceID                \
                            --across plugininstances                    \
                            --onCUBE "$CUBE"
        )
        status=$(echo $search | awk '{print $3}')
        echo -en "\033[1A\033[2K"
        opBlink_feedback    " $(date +%T), poll $pollCount "            \
                            "::Waiting on pinst $plugininstanceID..."   \
                            "state-->"                                  \
                            "  ${status}"
        windowBottom
        if [[ "$status" == "$state" ]] ; then break ; fi
        if (( b_notimeout )) ; then
            b_poll=1
        else
            if (( pollCount * pollIntervalSecodns < timeoutSeconds )) ; then
                b_poll=1
            else
                b_poll=0
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

function filesInNode_get {
    #
    # ARGS
    #       $1          CUBE instance to query
    #       $2          pluginInstance ID
    #       $3          file return string
    #
    # DESC
    #   Returns a string of all the files in a node.
    #
    # PRECONDITIONS
    #   Assume that pluginInstanceID has finished successfully!
    #
    local CUBE=$1
    local plugininstanceID=$2
    local __ret=$3
    local query=""

    echo -en "\033[2A\033[2K"

    opBlink_feedback    "  ${ADDRESS}:${PORT}  "                        \
                        "::Getting output file list..."                 \
                        "op-->"                                         \
                        "    query    "
    windowBottom
    query=$(
        chrispl-search  --for fname                                     \
                        --using plugin_inst_id=$plugininstanceID        \
                        --across files                                  \
                        --onCUBE "$CUBE"
    )
    echo -en "\033[3A\033[2K"
    opSolid_feedback    "  ${ADDRESS}:${PORT}  "                        \
                        "::File list collected..."                      \
                        "result-->"                                     \
                        "  $(echo "$query" | wc -l ) files  "
    eval $__ret="'$query'"
    windowBottom
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
    local __ret=$2
    local a_list=()

    for EL in "${a_feedflow[@]}" ; do
        EL="${EL//[$'\t\r\n ']}"
        if [[ ${EL:0:1} == [0-9]* ]] ; then
            PLUGIN=$(
                echo "$EL" | xargs                  |\
                            awk -F\| '{print $2}'  |\
                            awk -F\: '{print $2}'
            )
            a_list+=("$PLUGIN")
        fi
    done
    str_array="${a_list[@]}"
    eval $__ret="'$str_array'"
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
    local __ret=$3
    local IFS

    IFS=';' read -ra a_lookup <<< "$argLookup"
    for el in "${a_lookup[@]}" ; do
        IFS='='; read -r key val <<< "$el"
        argTemplate=${argTemplate//"$key"/"$val"}
    done
    eval $__ret="'$argTemplate'"
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

function plugin_run {
    #
    # ARGS
    #       $1          (sub)string name of plugin to run
    #       $2          array of feedflow specification
    #       $3          CUBE instance details
    #       $4          return ID of plugin instance
    #       $5          optional arg substitution lookup
    #
    # DESC
    #   Run a plugin image with appropriate args (and substitions)
    #   with supporting logic
    #
    local SEARCH="$1"
    local a_feedflow=("${!2}")
    local CUBE="$3"
    local __ret=$4
    local SUB="$5"

    local a_plugin=()
    local a_arg=()
    local a_cmd=()
    local pluginName=""
    local ID
    local PLUGINRUN
    local STATUSRUN
    local IFS

    pluginArray_filterFromWorkflow  "a_feedflow[@]" "a_plugin"
    a_plugin=($a_plugin)
    argArray_filterFromWorkflow     "a_feedflow[@]" "a_arg"
    a_arg=($a_arg)

    pidx=$(a_index $SEARCH "a_feedflow[@]")
    CUBE=$(echo $CUBE | jq -Mc )
    pluginName_filterFromWorkflow "a_feedflow[@]" "$SEARCH" "pluginName"
    if [[ "$pidx" != "-1" ]] ; then
        pidx=$(a_index $pluginName "a_plugin[@]")
        PLUGIN=${a_plugin[$pidx]}
        ARGS=${a_arg[$pidx]}
        if (( ${#SUB} )) ; then
            plugin_argsSub "$ARGS" "$SUB" ARGSUB
        else
            ARGSUB="$ARGS"
        fi
        cparse $PLUGIN "REPO" "CONTAINER" "MMN" "ENV"
        opBlink_feedback " $ADDRESS:$PORT " "::CUBE->$PLUGIN"           \
                         "op-->" " post run "
        windowBottom
        cmd="chrispl-run --plugin name=$CONTAINER                       \
                            --args \""$ARGSUB"\"                        \
                            --onCUBE "$CUBE"
        "
        IFS=' ' read -ra a_cmd <<< "$cmd"
        PLUGINRUN=$(${a_cmd[@]})
        STATUSRUN=$?
        if (( STATUSRUN == 0 )) ; then
            ID=$(echo $PLUGINRUN | awk '{print $3}')
        else
            ID=-1
        fi
        opRet_feedback  "$STATUSRUN"                                    \
                        " $ADDRESS:$PORT " "::CUBE->$PLUGIN"            \
                        "result-->" " pinst: $(echo $PLUGINRUN | awk '{print $3}')"
    else
        boxcenter "No matching plugin was found in the feedflow spec." ${Red}
        ID="-1"
    fi
    eval $__ret="'$ID'"
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
    leftID=$1
    op=$2
    action=$3
    result=$4

    # echo -e ''$_{1..8}'\b0123456789'
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
    leftID=$1
    op=$2
    action=$3
    result=$4

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
    leftID=$1
    op=$2
    action=$3
    result=$4

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
        "$b_respFail" " operation(s) had a failure response."               | ./boxes.sh
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
