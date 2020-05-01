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

_userRemoveShow(){
    if [[ "$#" -lt 2 ]]; then
        echo "fail"
        return 1
    else
        _USER="$1"
        shift 1
        _RAW_SHOW="$*"
        if [ "$( _readyUser "${_USER}" )" = "ok" ]; then
            _U_FILE="${CONFIG_DIR}/${_USER}/tvcmd/main.cfg"
            _SHOW="$( echo "${_RAW_SHOW}" | sed -s 's/[[:space:]\.\-]/_/g' )"
            _SHOW_LIST="$( < "${_U_FILE}" grep "shows" | sed -s 's/^shows = //g' )"
            if [[  "${_SHOW_LIST}" =~ ((\,[[:space:]]*)|^)${_SHOW}(((\,)+)|$) ]]; then
                _TMP="tmp$( date +%s ).file"
                < "${_U_FILE}" sed -s "s/${_SHOW}//" | sed "s/, ,/,/g" | sed -s "s/, $//g" | sed -s "s/^,//g" > "${_TMP}" && mv "${_TMP}" "${_U_FILE}" && rm -rf "${_TMP}"
                "${TVCMD_BIN}" "${TVCMD_OPTION}" "update" > /dev/null
            fi

            echo "removed"
        else
            echo "error"
            return 2
        fi
    fi

    return 0
}

_userAddShow(){
    if [[ "$#" -lt 2 ]]; then
        echo "fail"
        return 1
    else
        _USER="$1"
        shift 1
        _RAW_SHOW="$*"
        if [ "$( _readyUser "${_USER}" )" = "ok" ]; then
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
                _RES=''
                if _RES="$( ${TVCMD_BIN} ${TVCMD_OPTION} "update" )" ; then
                    if ( echo "${_RES}" | grep "${_SHOW} ... OK" ); then
                        echo "${_RES}"
                    else
                        _userRemoveShow "${_USER}" "${_RAW_SHOW}" > /dev/null
                        echo "not_found"
                        return 3
                    fi
                else
                    _userRemoveShow "${_USER}" "${_RAW_SHOW}" > /dev/null
                    echo "fail"
                    return 4
                fi
            fi
        else
            echo "error"
            return 2
        fi
    fi

    return 0
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
            yes | ${TVCMD_BIN} ${TVCMD_OPTION} "$*" | sed -e 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g' \
                    | sed -e "s/\"/''/g"
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

                _RES=""
                if  ! _RES="$( _userAddShow "${_USER}" "${_SHOW}" )"; then
                    echo "${_RES}"
                    return 6
                else
                    echo "${_RES}"
                fi
            fi
        ;;
        "RM_SHOW")
            if [[ "$#" -lt 1 ]]; then
                echo "no-show"
                return 2
            else
                _SHOW="$*"

                _RES=""
                if  ! _RES="$( _userRemoveShow "${_USER}" "${_SHOW}" )"; then
                    echo "${_RES}"
                    return 7
                else
                    echo "${_RES}"
                fi
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
