#!/bin/bash


echoerr() { echo "$@" 1>&2; }

_py_from_get_value(){
    if [[ $# -lt 2 ]]; then
        return 1
    fi
    JSON_STRING="$( echo "$1" | sed -e "s/\x1b\[.\{1,5\}m//g" )"
    KEY="$2"

    PYTHON_CODE="import sys; import json; \
        data=json.loads('${JSON_STRING}'); \
        v= data[\"${KEY}\"] if \"${KEY}\" in data else ''; \
        print(v);"
    RES=''
    if RES="$( python -c "${PYTHON_CODE}" )"; then
        echo "${RES}" | sed -e "s/'/\"/g"
        return 0
    else
        return 2
    fi
}

_resp_register(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "REGISTER ERROR ${DETAILS}";
    ;;
    "exists")
        echo "REGISTER UNAVAILABLE";
    ;;
    "success")
        echo "REGISTER VALID";
    ;;
    *)
        echo "REGISTER UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_change_pass(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "CHANGE_PASS ERROR ${DETAILS}";
    ;;
    "refused")
        echo "CHANGE_PASS REFUSED";
    ;;
    "success")
        echo "CHANGE_PASS CHANGED";
    ;;
    *)
        echo "CHANGE_PASS UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_connect(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "CONNECT ERROR ${DETAILS}";
    ;;
    "connected")
        echo "CONNECT CONNECTED";
    ;;
    *)
        echo "CONNECT UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_disconnect(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "DISCONNECT ERROR ${DETAILS}";
    ;;
    "disconnected")
        echo "DISCONNECT DISCONNECTED";
    ;;
    *)
        echo "DISCONNECT UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_request(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "REQUEST ERROR ${DETAILS}";
    ;;
    "session-expired")
        echo "REQUEST EXPIRED";
    ;;
    "session-invalid")
        echo "REQUEST INVALID";
    ;;
    "unknown")
        echo "REQUEST UNRECOGNIZED ${DETAILS}";
    ;;
    "no-session")
        echo "REQUEST NO-SESSION";
    ;;
    "connection-error")
        echo "REQUEST NO-CONNECTION";
    ;;
    "disconnected")
        echo "REQUEST DISCONNECTED";
    ;;
    *)
        echo "REQUEST UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_process(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "PROCESS ERROR ${DETAILS}";
    ;;
    *)
        echo "PROCESS UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_request_process(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "REQUEST_PROCESS ERROR ${DETAILS}";
    ;;
    *)
        echo "REQUEST_PROCESS UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_get_url(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "GET_URL ERROR ${DETAILS}";
    ;;
    "found")
        echo "GET_URL FOUND ${DETAILS}"
    ;;
    *)
        echo "GET_URL UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_set_url(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "SET_URL ERROR ${DETAILS}";
    ;;
    "done")
        echo "SET_URL SET ${DETAILS}"
    ;;
    *)
        echo "SET_URL UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}

_resp_tvcmd_process(){
    if [[ $# -lt 2 ]]; then
        echo "ERROR BAD-ANSWER"
        return 1
    fi

    STATUS="$1"
    DETAILS="$2"

    case "${STATUS}" in
    "error")
        echo "TV_CMD ERROR ${DETAILS}";
    ;;
    "useless")
        echo "TV_CMD USELESS";
    ;;
    "script-fail")
        echo "TV_CMD SCRIPT_FAILURE";
    ;;
    "no-show")
        echo "TV_CMD NO-SHOW ${DETAILS}";
    ;;
    "no-cmd")
        echo "TV_CMD NO-CMD ${DETAILS}";
    ;;
    "invalid-cmd")
        echo "TV_CMD INVALID-CMD ${DETAILS}";
    ;;
    "unknown-error")
        echo "TV_CMD UNKNOWN-ERROR ${DETAILS}";
    ;;
    "success")
        echo "TV_CMD SUCCESS ${DETAILS}";
    ;;
    *)
        echo "REQUEST_PROCESS UNKNOWN-STATUS";
        return 2
    ;;
    esac

    return 0
}


process_answer(){
    if [[ $# -lt 1 ]]; then
        return 1
    fi
    
    JSON_STRING="$1"
    TYPE=""
    if TYPE="$( _py_from_get_value "${JSON_STRING}" request )"; then
        case "${TYPE}" in
        "register")
            if ! _resp_register "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_register returned code $?"
                return 5
            fi
        ;;
        "change_pass")
            if ! _resp_change_pass "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_change_pass returned code $?"
                return 6
            fi
        ;;
        "connect")
            if ! _resp_connect "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_connect returned code $?"
                return 6
            fi
        ;;
        "disconnect")
            if ! _resp_disconnect "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_disconnect returned code $?"
                return 7
            fi
        ;;
        "request")
            if ! _resp_request "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_request returned code $?"
                return 8
            fi
        ;;
        "process")
            if ! _resp_process "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_process returned code $?"
                return 9
            fi
        ;;
        "request_process")
            if ! _resp_request_process "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_request_process returned code $?"
                return 10
            fi
        ;;
        "TVCMD")
            if ! _resp_tvcmd_process "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_tvcmd_process returned code $?"
                return 11
            fi
        ;;
        "get_url")
            if ! _resp_get_url "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_get_url returned code $?"
                return 12
            fi
        ;;
        "set_url")
            if ! _resp_set_url "$( _py_from_get_value "${JSON_STRING}" status )" "$( _py_from_get_value "${JSON_STRING}" details )"; then
                echoerr "_resp_set_url returned code $?"
                return 12
            fi
        ;;
        "quit")
            echo "QUIT"
            exit 0
        ;;
        *)
            return 3
        ;;
        esac

        return 0
    else
        return 2
    fi
}

trap 'echo "QUIT"; exit 0'  INT QUIT TERM;

while read -r L_INPUT; do
    RET=""
    if ! RET="$( process_answer "${L_INPUT}" )"; then
        echo "ANWSER_READ ERROR ${RET}";
    else
        echo "${RET}"
    fi
done
