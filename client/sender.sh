#!/bin/bash

echoerr() { echo "$@" 1>&2; }

SCRIPT_DIR="$( realpath "$( dirname "$0" )" )"
URL_FILE="url"

URL="$( cat "${URL_FILE}" )"

CURL_MAX_TIME="10"

_send(){
    if [[ $# -lt 2 ]]; then
        echoerr "[send] need 'user' and 'request'"
        return 1
    fi

    if [ "${URL}" = "" ]; then
        echoerr "URL not set ";
        return 3
    fi

    _USER="$1"
    _REQUEST="$2"
    _PASS=""
    _ARGS=""
    shift 2
    
    while [[ $# -gt 0 ]]; do
        if [ "$1" = "-p" ]; then
            shift 1
            if [[ $# -lt 1 ]]; then
                echoerr "No pass provided"
            else
                _PASS="$1"
                shift 1
            fi
        else
            _ARGS="${_ARGS} $1"
            shift 1
        fi
    done

    if curl --silent --max-time "${CURL_MAX_TIME}" --data "user=${_USER}" --data "request=${_REQUEST}" --data "pass=${_PASS}" --data "args=${_ARGS}" "${URL}"; then
        return 0
    else
        echo "{\"request\":\"send\", \"status\":\"fail\", \"details\":\"Could not connect to ${URL}\"}"
        echoerr "[send] curl failed"
        return 2
    fi
}


_cmd_login(){
    if [[ $# -lt 2 ]]; then
        echoerr "[cmd_login] need 'login' and 'pass'"
        return 2
    fi

    _USER="$1"
    _PASS="$2"

    _send "${_USER}" CONNECT -p "${_PASS}"

    return 0
}

_cmd_logout(){
    if [[ $# -lt 1 ]]; then
        echoerr "[cmd_logout] need 'user'"
        return 2
    fi

    _USER="$1"

    _send "${_USER}" DISCONNECT

    return 0
}

_cmd_register(){
    if [[ $# -lt 2 ]]; then
        echoerr "[cmd_register] need 'user' and 'pass'"
        return 2
    fi

    _USER="$1"
    _PASS="$2"

    _send "${_USER}" REGISTER -p "$_PASS"

    return 0
}

_cmd_change_pass(){
    if [[ $# -lt 3 ]]; then
        echoerr "[cmd_change_pass] need 'user', 'old_pass' and 'new_pass'"
        return 2
    fi

    _USER="$1"
    _OLD_PASS="$2"
    _NEW_PASS="$3"

    _send "${_USER}" CHANGE_PASS -p "${_OLD_PASS}" "${_NEW_PASS}"
    
    return 0
}

_cmd_request(){
    if [[ $# -lt 3 ]]; then
        echoerr "[cmd_request] need 'user', 'target' and 'command' and eventually your command [args]"
        return 2
    fi

    _USER="$1"
    _TARGET="$2"
    _CMD="$3"
    shift 3

    _send "${_USER}" REQUEST "${_TARGET}" "${_CMD}" "$@"
}

_cmd_url_set(){
    if [[ $# -lt 1 ]]; then
        echoerr "[cmd_url_set] no url given…"
        return 1
    fi

    _URL="$1"
    if [[ "${_URL}" =~ ^(https?|ftp|file)://[-A-Za-z0-9\+\&@#/%?=~_|\!:,.\;]*[-A-Za-z0-9\+\&@#/%=~_|]$ ]]; then
        URL="${_URL}"
        echo "${_URL}" > "${URL_FILE}"
        echo "{\"request\":\"set_url\", \"status\":\"done\", \"details\":\"${_URL}\"}"
        return 0
    else
        echoerr "[cmd_url_set] malformed url?"
        return 5
    fi
}

_cmd_url_get(){
    if [ "${URL}" != "" ]; then
        echo "{\"request\":\"get_url\", \"status\":\"found\", \"details\":\"${URL}\"}"
    else
        echoerr "[cmd_url_get] not url set…"
        echo "{\"request\":\"get_url\", \"status\":\"missing\", \"details\":\"no url found\"}"
        return 6
    fi
}

quit_cmd(){
    _cmd_logout "$@" > /dev/null
    echo "{\"request\":\"quit\"}"
    # echoerr "ah"
    exit 0
}

process_cmd(){
    if [[ $# -lt 1 ]]; then
        echoerr "[process_cmd] no command"
        return 1
    fi
    
    _CMD="$1"
    shift 1
    case "${_CMD}" in
    "LOGIN")
        _cmd_login "$@"
    ;;
    "LOGOUT")
        _cmd_logout "$@"
    ;;
    "REGISTER")
        _cmd_register "$@"
    ;;
    "CHANGE_PASS")
        _cmd_change_pass "$@"
    ;;
    "REQUEST")
        _cmd_request "$@"
    ;;
    "URL_SET")
        _cmd_url_set "$1"
    ;;
    "URL_GET")
        _cmd_url_get
    ;;
    "QUIT")
        quit_cmd
    ;;
    *)
        echoerr "[process_cmd] unknown command '${_CMD}'"
        return 4;
    ;;
    esac

    return 0
}




if [ "${URL}" != "" ]; then
    echo "{\"request\":\"set_url\", \"status\":\"done\", \"details\":\"${URL}\"}"
fi
trap 'quit_cmd' INT QUIT TERM;
while read -r L_INPUT; do
    process_cmd ${L_INPUT}
done

quit_cmd
