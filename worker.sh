#!/bin/bash


depend_check() {
    for arg; do
		hash "$arg" 2>/dev/null || { echo "{\"request\":\"process\", \"status\":\"error\", \"details\":\"script-fail: ${arg} missing\"}"; exit -1; }
    done    
}

py3_package_check() {
    for arg; do
        python3 -c "import $arg" 2>/dev/null || { echo "{\"request\":\"process\", \"status\":\"error\", \"details\":\"script-fail: $arg missing python package."; exit -1; }
    done
}

echoerr() { echo "$@" 1>&2; }


depend_check "tvcmd"
depend_check "openssl"
py3_package_check "json"



source tvcmd_wrapper.sh


cmd_request_process(){
    if [[ $# -lt 2 ]]; then
        echo "TV_CMD ERROR 'process_request: not enough parameters given'"
    else
        _COMMAND="$1"
        _REQUEST="$2"

        shift 2
        case "${_REQUEST}" in
        "TVCMD")
            _RES=""
            if _RES="$( TVCMD_processUserCommand $* )"; then
                case "${_RES}" in
                "present")
                    echo "TV_CMD USELESS";
                ;;
                *)
                    _RET="TV_CMD SUCCESS {"
                    _LINES="$( echo "${_RES}" | ( _I=1; while read -r LINE; do echo -n "\"line${_I}\":\"${LINE}\", "; _I=$(( _I + 1 )); done; echo -n \"line_count\":$(( _I - 1 )) ) )"
                    _RET="${_RET}\"invoked\":\"$*\", ${_LINES}}"
                    
                    echo "${_RET}" | sed -e 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g'
                ;;
                esac
            else
                case "${_RES}" in
                "fail")
                    echo "TV_CMD SCRIPT_FAILURE";
                ;;
                "no-show")
                    echo "TV_CMD NO-SHOW '$*'"
                ;;
                "no-cmd")
                    echo "TV_CMD NO-CMD '$*: tvcmd command not found/recognized'"
                ;;
                "error")
                    echo "TV_CMD ERROR '$* error: ${_RES}'"
                ;;
                "bad-cmd")
                    echo "TV_CMD INVALID-CMD '$* invalid: bad command'"
                ;;
                "not_found")
                    echo "TV_CMD SHOW-NOT-FOUND  '$* show not found…'"
                ;;
                *)
                    echo "TV_CMD UNKNOWN-ERROR '$* unknown error: ${_RES}'"
                ;;
                esac
            fi
        ;;
        *)
            echo "REQUEST UNRECOGNIZED '$*'"
        ;;
        esac
    fi
}

quit_cmd(){
    echo "QUIT"
    exit 0
}

process_command(){
    if [[ $# -lt 1 ]]; then
        echo "REQUEST_PROCESS ERROR 'process_command: not enough parameters given'"
        return 1
    else
        _COMMAND="$1"
        shift 1
        case "${_COMMAND}" in
        "REQUEST")
            if [[ $# -lt 1 ]]; then
                echo "REQUEST_PROCESS ERROR 'request process: missing parameters'"
            else
                cmd_request_process "${_COMMAND}" "$@"
            fi
        ;;
        "QUIT")
            quit_cmd
        ;;
        *)
            echo "REQUEST_PROCESS ERROR 'process_command: bad command ( \\\"${_COMMAND}\\\" )'"
            return 3
        ;;
        esac

        return 0
    fi
}


trap 'quit_cmd' INT QUIT TERM;
while read -r L_INPUT; do
    process_command ${L_INPUT}
done

quit_cmd