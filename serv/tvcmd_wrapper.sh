#!/bin/bash


CONFIG_DIR="data"

TVCMD_BIN="/bin/tvcmd"
TVCMD_OPTION="-e"

_isUserReady(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
    else
        _USER="$1"
        if [ -f "${CONFIG_DIR}/${_USER}/tvcmd/main.cfg" ]; then
            echo "ok"
        else
            echo "no"
        fi
    fi
}

_readyUser(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
    else
        _USER="$1"
        if [ "$( _isUserReady "${_USER}" )" != "ok" ]; then
            _TXT="[general]\nsource = thetvdb\nshows = \nformats = https://search.torrents.io"
            if  mkdir -p "${CONFIG_DIR}/${_USER}/tvcmd" && (echo -e "${_TXT}" > "${CONFIG_DIR}/${_USER}/tvcmd/main.cfg" )  then
                echo "ok"
            else
                echo "error"
            fi
        else
            echo "ok"
        fi
    fi
}

_userAddShow(){
    if [[ "$#" -lt 2 ]]; then
        echo "fail"
    else
        _USER="$1"
        shift 1
        _RAW_SHOW="$*"
        if [ "$( _readyUser "${_USER}")" = "ok" ]; then
            _U_FILE="${CONFIG_DIR}/${_USER}/tvcmd/main.cfg"
            _SHOW="$( echo "${_RAW_SHOW}" | sed -s 's/[[:space:]\.\-]/_/g' )"
            _SHOW_LIST="$( < "${_U_FILE}" grep "shows" | sed -s 's/^shows = //g' )"
            if [[  "${_SHOW_LIST}" =~ ((\,[[:space:]]*)|^)${_SHOW}(((\,)+)|$) ]]; then
                echo "present"
            else
                _TMP="tmp$( date +%s ).file"
                < "${_U_FILE}" sed -s "s/shows = ${_SHOW_LIST}/shows = ${_SHOW_LIST}\, ${_SHOW}/" > "${_TMP}" && mv "${_TMP}" "${_U_FILE}" && rm -rf "${_TMP}"
                
                export XDG_CONFIG_HOME="${CONFIG_DIR}/${_USER}"
                export XDG_CACHE_HOME="${CONFIG_DIR}/${_USER}"
                if ! ( ${TVCMD_BIN} ${TVCMD_OPTION} "update" ); then
                    echo "fail"
                fi
            fi
        else
            echo "error"
        fi
    fi
}

_userCommand(){
    if [[ "$#" -lt 2 ]]; then
        echo "fail"
        return 1
    else
        _USER="$1"
        shift 1
        if [ "$( _readyUser "${_USER}")" = "ok" ]; then
            export XDG_CONFIG_HOME="${CONFIG_DIR}/${_USER}"
            export XDG_CACHE_HOME="${CONFIG_DIR}/${_USER}"
            ${TVCMD_BIN} ${TVCMD_OPTION} "$*"
            return $?
        else
            echo "error"
            return 2
        fi
    fi
}


TVCMD_processUserCommand(){
    if [[ "$#" -lt 2 ]]; then
        echo "fail"
        return 1
    else
        _USER="$1"
        _CMD="$2"
        shift 2

        case "${_CMD}" in
        "ADD_SHOW")
            if [[ "$#" -lt 1 ]]; then
                echo "no-show"
                return 2
            else
                _SHOW="$*"

                _userAddShow "${_USER}" "${_SHOW}"
            fi
        ;;
        "COMMAND")
            if [[ "$#" -lt 1 ]]; then
                echo "no-cmd"
                return 3
            else
                _RES=""
                if  ! _RES="$( _userCommand "${_USER}" "$*" )"; then
                    echo "${_RES}"
                    return 5
                else
                    echo "${_RES}"
                fi
            fi
        ;;
        *)
            echo "bad-cmd"
            return 4
        ;;
        esac
    fi

    return 0
}
