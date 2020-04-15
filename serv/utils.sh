#!/bin/bash




KP_F="kp.pem"

U_DIR="sss"


g_k(){
    if ! [ -f "${KP_F}" ]; then
        if openssl genrsa -out "${KP_F}" 2048 > /dev/null 2>&1; then
            echo "ok"
        else
            chmod 700 "${KP_F}"  > /dev/null 2>&1
            echo "err"
        fi
    else
        chmod 700 "${KP_F}"  > /dev/null 2>&1
        echo "exists"
    fi
}

s_w_k(){
    _STR="$1"
    _TMP="tmp$( date +%s ).sha56"
    _R_G_K="$( g_k )"
    if [ "${_R_G_K}" = "ok" ] || [ "${_R_G_K}" = "exists" ]; then
        if ( echo "${_STR}" | openssl dgst -sha256 -sign "${KP_F}" -out "${_TMP}" ); then
            ( openssl base64 -in "${_TMP}" ) || echo "err"
            rm -rf "${_TMP}" > /dev/null 2>&1
        else
            rm -rf "${_TMP}" > /dev/null 2>&1
            echo "err"
        fi
    else
        echo "err-key"
    fi
}

m_s(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _STR="$1"
        _SIG="$2"
        
        _STR_SIG="$( s_w_k "${_STR}" )"
        case "${_STR_SIG}" in
        "err")
            echo "sign-err"
            ;;
        "no-key")
            echo "no-sign-key"
            ;;
        *)
            if [ "${_STR_SIG}" = "${_SIG}" ]; then
                echo "true"
            else
                echo "false"
            fi
        esac
    fi
}

n_u_p(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _PWD="$2"

        _PWD="$( s_w_k "$2" )"
        case "${_PWD}" in
        "err")
            echo "pwd-sign-err"
            ;;
        "no-key")
            echo "pwd-no-key"
            ;;
        *)
            _U_FILENAME="${_USER}.json"
            _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

            mkdir -p "${U_DIR}"  > /dev/null 2>&1

            if [ -f "${_U_FILEPATH}" ] || ( echo "{}" > "${_U_FILEPATH}" ) ; then
                _TMP="tmp$( date +%s ).file"
                ( < "${_U_FILEPATH}" python -c \
                    "import sys; import json; \
                    data=json.load(sys.stdin); \
                    data[\"user\"]=\"${_USER}\"; \
                    data[\"pwd\"]=\"\"\"${_PWD}\"\"\"; \
                    print(data);" | tr "'" '"'\
                > "${_TMP}" && mv "${_TMP}" "${_U_FILEPATH}" && rm -rf "${_TMP}" )
                chmod 700 -R "${U_DIR}"  > /dev/null 2>&1
                echo "done"
            else
                echo "file-access-err"
            fi
            ;;
        esac
    fi
}

r(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _PWD="$2"

        _U_FILENAME="${_USER}.json"
        _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

        if [ -f "${_U_FILEPATH}" ]; then
            echo "exists"
        else
            _N_U_P_RES="$( n_u_p "${_USER}" "${_PWD}" )"

            if [ "${_N_U_P_RES}" = "done" ]; then
                echo "done"
            else
                echo "register-${_N_U_P_RES}"
            fi
        fi
    fi
}

ch_p(){
    if [[ $# -lt 3 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _OLD_PWD="$2"
        _NEW_PWD="$3"

        _U_FILENAME="${_USER}.json"
        _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

        if [ -f "${_U_FILEPATH}" ]; then
            _OLD_PWD="$( s_w_k "$_OLD_PWD" )"
            _NEW_PWD="$( s_w_k "$_NEW_PWD" )"

            _RES="$( < "${_U_FILEPATH}" python -c \
                "import sys; import json; \
                data= json.load(sys.stdin); \
                user= data[\"user\"] if (\"user\" in data) else ''; \
                pwd= data[\"pwd\"] if (\"pwd\" in data) else ''; \
                print(''+user+':'+pwd);" )"

            if [ "${_RES}" = "${_USER}:${_OLD_PWD}" ]; then
                _TMP="tmp$( date +%s ).file"
                < "${_U_FILEPATH}" python -c \
                    "import sys; import json; \
                    data=json.load(sys.stdin); \
                    data[\"user\"]=\"${_USER}\"; \
                    data[\"pwd\"]=\"\"\"${_NEW_PWD}\"\"\"; \
                    print(data);" | tr "'" '"' \
                > "${_TMP}" && mv "${_TMP}" "${_U_FILEPATH}" && rm -rf "${_TMP}"
                echo "done"
            else
                echo "refused"
            fi
        else
            echo "fail"
        fi
    fi
}

c_m(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _PWD="$2"

        _PWD="$( s_w_k "$_PWD" )"
        case "${_PWD}" in
        "err")
            echo "pwd-sign-err"
            ;;
        "no-key")
            echo "pwd-no-key"
            ;;
        *)
            _U_FILENAME="${_USER}.json"
            _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

            if ! [ -f "${_U_FILEPATH}" ] ; then
                echo "fail"
            else
                _RES="$( < "${_U_FILEPATH}" python -c \
                    "import sys; import json; \
                    data=json.load(sys.stdin); \
                    user= data[\"user\"] if (\"user\" in data) else ''; \
                    pwd= data[\"pwd\"] if (\"pwd\" in data) else ''; \
                    print(''+user+':'+pwd);" )"
                
                if [ "${_RES}" = "${_USER}:${_PWD}" ]; then
                    echo "success"
                else
                    echo "fail"
                fi
            fi
        ;;
        esac
    fi
}

c(){
    if [[ $# -lt 3 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _PWD="$2"
        _ADDR="$3"

        _CRED_MATCH="$( c_m "${_USER}" "${_PWD}" )"
        if [ "${_CRED_MATCH}" = "success" ]; then
            _U_FILENAME="${_USER}.json"
            _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

            if ! [ -f "${_U_FILEPATH}" ] ; then
                echo "cnct-no-user"
            else
                _TMP="tmp$( date +%s ).file"
                < "${_U_FILEPATH}" python -c \
                    "import sys; import json; \
                    data=json.load(sys.stdin); \
                    data[\"ip\"]=\"${_ADDR}\"; \
                    data[\"stamp\"]=\"$( date +%s )\"; \
                    print(data);" | tr "'" '"' \
                > "${_TMP}" && mv "${_TMP}" "${_U_FILEPATH}" && rm -rf "${_TMP}"
                echo "done"
            fi
        elif [ "${_CRED_MATCH}" = "fail" ]; then
            echo "fail"
        else
            echo "cnct-err-${_CRED_MATCH}"
        fi
    fi
}

i_c(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _ADDR="$2"

        _U_FILENAME="${_USER}.json"
        _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

        if ! [ -f "${_U_FILEPATH}" ] ; then
            echo "ch-cnct-no-user"
        else
            _RES="$( < "${_U_FILEPATH}" python -c \
                "import sys; import json; \
                data=json.load(sys.stdin); \
                ip= data[\"ip\"] if (\"ip\" in data) else ''; \
                stamp= data[\"stamp\"] if (\"stamp\" in data) else ''; \
                print(ip+':'+stamp);" )"

            _S_ADDR="$( echo "${_RES}" | cut -d: -f1 )"
            if [ "${_S_ADDR}" != "" ] && [ "${_S_ADDR}" = "${_ADDR}" ]; then
                if [[ "$(( "$( date +%s ) - $( echo "${_RES}" | cut -d: -f2 )" ))" -gt 900 ]]; then
                    echo "timeout"
                else
                    echo "connected"
                fi
            elif [ "${_S_ADDR}" = "" ]; then
                echo "disconnected"
            else
                echo "elsewhere"
            fi
        fi
    fi
}

t_r(){
    if [[ $# -lt 2 ]]; then
        echo "missing-arg"
    else
        _USER="$1"
        _ADDR="$1"

        _IS_CTD_RES="$( i_c "${_USER}" "${_ADDR}" )"

        if [ "${_IS_CTD_RES}" = "success" ]; then

            _U_FILENAME="${_USER}.json"
            _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

            if [ -f "${_U_FILEPATH}" ] ; then
                _TMP="tmp$( date +%s ).file"
                < "${_U_FILEPATH}" python -c \
                    "import sys; import json; \
                    data=json.load(sys.stdin); \
                    data[\"stamp\"]=\"$( date +%s )\"; \
                    print(data);" | tr "'" '"' \
                > "${_TMP}" && mv "${_TMP}" "${_U_FILEPATH}" && rm -rf "${_TMP}"
                echo "done"
            else
                echo "time-r-no-user"
            fi
        else
            echo "time-f-${_IS_CTD_RES}"
        fi
    fi
}

dc(){
    if [[ $# -lt 1 ]]; then
        echo "missing-arg"
    else
        _USER="$1"

        _U_FILENAME="${_USER}.json"
        _U_FILEPATH="${U_DIR}/${_U_FILENAME}"

        if [ -f "${_U_FILEPATH}" ] ; then
            _TMP="tmp$( date +%s ).file"
            < "${_U_FILEPATH}" python -c \
                "import sys; import json; \
                data=json.load(sys.stdin); \
                data[\"ip\"]=\"\"; \
                print(data);" | tr "'" '"' \
            > "${_TMP}" && mv "${_TMP}" "${_U_FILEPATH}" && rm -rf "${_TMP}"
            echo "done"
        else
            echo "dc-no-user"
        fi
    fi

}

