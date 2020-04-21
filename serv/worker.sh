#!/bin/bash


source utils.sh
source tvcmd_wrapper.sh

echoerr() { echo "$@" 1>&2; }


cmd_register(){
    if [[ $# -lt 2 ]]; then
        echo "{\"request\":\"register\", \"status\":\"error\", \"details\":\"connect: not enough parameters given\"}"
    else
        _USER="$1"
        _PWD="$2"

        _REGISTER_RES="$( r "${_USER}" "${_PWD}" )"

        if [ "${_REGISTER_RES}" = "done" ]; then
            echo "{\"request\":\"register\", \"status\":\"success\", \"details\":\"successfully registered\"}"
        elif [ "${_REGISTER_RES}" = "exists" ]; then
            echo "{\"request\":\"register\", \"status\":\"exists\", \"details\":\"user already exists\"}"
        else
            echo "{\"request\":\"register\", \"status\":\"error\", \"details\":\"register: failed\"}"
            echoerr "connection attempt for user '${_USER}' ended with answer '${_REGISTER_RES}'"
        fi
    fi
}

cmd_change_pass(){
    if [[ $# -lt 3 ]]; then
        echo "{\"request\":\"change_pass\", \"status\":\"error\", \"details\":\"change pass: not enough parameters given\"}"
    else
        _USER="$1"
        _OLD_PWD="$2"
        _NEW_PWD="$3"

        _CH_PASS_RES="$( ch_p "${_USER}" "${_OLD_PWD}" "${_NEW_PWD}" )"

        if [ "${_CH_PASS_RES}" = "done" ]; then
            echo "{\"request\":\"change_pass\", \"status\":\"success\", \"details\":\"password changed\"}"
        elif [ "${_CH_PASS_RES}" = "refused" ]; then
             echo "{\"request\":\"change_pass\", \"status\":\"refused\", \"details\":\"change pass: refused\"}"
        else
             echo "{\"request\":\"change_pass\", \"status\":\"error\", \"details\":\"change pass: failed\"}"
             echoerr "change password attempt for user '${_USER}' ended with answer '${_CH_PASS_RES}'"
        fi
    fi
}

cmd_connect(){
    if [[ $# -lt 3 ]]; then
        echo "{\"request\":\"connect\", \"status\":\"error\", \"details\":\"connect: not enough parameters given\"}"
    else
        _USER="$1"
        _ADDR="$2"
        _PWD="$3"

        _CONNECT_RES="$( c "${_USER}" "${_PWD}" "${_ADDR}" )"

        if [ "${_CONNECT_RES}" = "done" ]; then
            echo "{\"request\":\"connect\", \"status\":\"connected\", \"details\":\"succesfully connected\"}"
        else
            echo "{\"request\":\"connect\", \"status\":\"error\", \"details\":\"connect: connexion failed\"}"
            echoerr "connection attempt for user '${_USER}' (${_ADDR}) ended with answer '${_CONNECT_RES}'"
        fi
    fi
}

cmd_disconnect(){
    if [[ $# -lt 1 ]]; then
        echo "{\"request\":\"disconnect\", \"status\":\"error\", \"details\":\"disconnect: not enough parameters\"}"
    else
        _USER="$1"

        _DC_RES="$( dc "${_USER}" )"

        echo "{\"request\":\"disconnect\", \"status\":\"disconnected\", \"details\":\"succesfully disconnected\"}"

        if [ "${_DC_RES}" != "done" ]; then
            echoerr "Warning: disconnecting '${_USER}' resulted with '${_DC_RES}'"
        fi
    fi

}

cmd_request_process(){
    if [[ $# -lt 3 ]]; then
        echo "{\"request\":\"request\", \"status\":\"error\", \"details\":\"process_request: not enough parameters given\"}"
    else
        _USER="$1"
        _ADDR="$2"
        _COMMAND="$3"

        shift 3
        if [[ $# -lt 1 ]]; then
            echo "{\"request\":\"request\", \"status\":\"error\", \"details\":\"process_request: no request\"}"
        else
            _CNCT_TEST="$( i_c "${_USER}" "${_ADDR}" )"
            case "${_CNCT_TEST}" in
            "timeout")
                echo "{\"request\":\"request\", \"status\":\"session-expired\", \"details\":\"connection_process_request: connection timeout\"}"
            ;;
            "elsewhere")
                echo "{\"request\":\"request\", \"status\":\"session-invalid\", \"details\":\"connection_process_request: invalid session\"}"
                cmd_disconnect "${_USER}"
            ;;
            "disconnected")
                echo "{\"request\":\"request\", \"status\":\"disconnected\", \"details\":\"connection_process_request: user disconnected\"}"
            ;;
            "connected")
                _REQUEST="$1"
                shift 1
                case "${_REQUEST}" in
                "TVCMD")
                    _RES=""
                    if _RES="$( TVCMD_processUserCommand "${_USER}" $* )"; then
                        case "${_RES}" in
                        "present")
                            echo "{\"request\":\"TVCMD\", \"status\":\"useless\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"': show already added\"}"
                        ;;
                        *)
                            _RET="{\"request\":\"TVCMD\", \"status\":\"success\", \"details\":{"
                            _LINES="$( echo "${_RES}" | ( _I=1; while read -r LINE; do echo -n "\"line${_I}\":\"${LINE}\", "; _I=$(( _I + 1 )); done; echo -n \"line_count\":$(( _I - 1 )) ) )"
                            _RET="${_RET}\"invoked\":\"$*\", ${_LINES}}}"
                            
                            echo "${_RET}"
                        ;;
                        esac
                    else
                        case "${_RES}" in
                        "fail")
                            echo "{\"request\":\"TVCMD\", \"status\":\"script-fail\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"': ${_RES}\"}"
                        ;;
                        "no-show")
                            echo "{\"request\":\"TVCMD\", \"status\":\"no-show\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"': show not found/recognized\"}"
                        ;;
                        "no-cmd")
                            echo "{\"request\":\"TVCMD\", \"status\":\"no-cmd\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"': tvcmd command not found/recognized\"}"
                        ;;
                        "error")
                            echo "{\"request\":\"TVCMD\", \"status\":\"error\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"' error: ${_RES}\"}"
                        ;;
                        "bad-cmd")
                            echo "{\"request\":\"TVCMD\", \"status\":\"invalid-cmd\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"' invalid: bad command\"}"
                        ;;
                        *)
                            echo "{\"request\":\"TVCMD\", \"status\":\"unknown-error\", \"details\":\"'TVCMD_processUserCommand "${_USER}" "$*"' unknown error: ${_RES}\"}"
                        ;;
                        esac
                    fi

                ;;
                *)
                    echo "{\"request\":\"request\", \"status\":\"unknown\", \"details\":\"process_request: unknown request '${_REQUEST}'\"}"
                ;;
                esac
            ;;
            "ch-cnct-no-user")
                echo "{\"request\":\"request\", \"status\":\"no-session\", \"details\":\"process_request: no session available for '${_USER}'\"}"
            ;;
            *)
                echo "{\"request\":\"request\", \"status\":\"connection-error\", \"details\":\"process_request: can't connect for '${_USER}'\"}"
                echoerr "Connection error on request: ${_CNCT_TEST}"
            ;;
            esac
        fi

    fi
}

process_command(){
    if [[ $# -lt 2 ]]; then
        echo "{\"request\":\"process\", \"status\":\"error\", \"details\":\"process_command: not enough parameters given\"}"
        return 1
    else
        _USER="$1"
        _COMMAND="$2"
            shift 2
        case "${_COMMAND}" in
        "REGISTER")
            if [[ $# -lt 1 ]]; then
                echo "{\"request\":\"register\", \"status\":\"error\", \"details\":\"register command: missing parameter\"} ($*) $#"
                return 2
            else
                _PWD="$1"
                cmd_register "${_USER}" "${_PWD}"
            fi
        ;;
        "CHANGE_PASS")
            if [[ $# -lt 2 ]]; then
                echo "{\"request\":\"change_pass\", \"status\":\"error\", \"details\":\"change pass command: missing parameters\"} ($*) $#"
                return 2
            else
                _OLD_PASS="$1"
                _NEW_PASS="$2"

                cmd_change_pass "${_USER}" "${_OLD_PASS}" "${_NEW_PASS}"
            fi
        ;;
        "CONNECT")
            if [[ $# -lt 2 ]]; then
                echo "{\"request\":\"connect\", \"status\":\"error\", \"details\":\"connect command: missing parameters\"}"
                return 2
            else
                _ADDR="$1"
                _PWD="$2"
                cmd_connect "${_USER}" "${_ADDR}" "${_PWD}"
            fi
        ;;
        "DISCONNECT")
            cmd_disconnect "${_USER}"
        ;;
        "REQUEST")
            if [[ $# -lt 1 ]]; then
                echo "{\"request\":\"request_process\", \"status\":\"error\", \"details\":\"request process: missing parameters\"}"
            else
                _ADDR="$1"
                shift 1
                cmd_request_process "${_USER}" "${_ADDR}" "${_COMMAND}" "$@"
            fi
        ;;
        *)
            echo "{\"request\":\"process\", \"status\":\"error\", \"details\":\"process_command: bad command ( \\\"${_COMMAND}\\\" )\"}"
            return 3
        ;;
        esac

        return 0
    fi
}


if [[ $# -lt 2 ]]; then
    echoerr "usage: username command [command-args] …"

    exit 1 
else
    _USER="$1"
    _COMMAND="$2"

    shift 2
    process_command "${_USER}" "${_COMMAND}" "$@"
    exit $?
fi