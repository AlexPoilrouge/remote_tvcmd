#!/bin/bash

echoerr() { echo "$@" 1>&2; }

URL="https://alexandre.hurstel.eu/test/index.php"

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

    if curl --silent --data "user=${_USER}" --data "request=${_REQUEST}" --data "pass=${_PASS}" --data "args=${_ARGS}" ${URL}; then
        return 0
    else
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
    "QUIT")
        exit 0
    ;;
    *)
        echoerr "[process_cmd] unkown command '${_CMD}'"
        return 1;
    ;;
    esac

    return 0
}

process_cmd $*