#!/bin/bash


CONFIG_DIR="data"

TVCMD_BIN="/bin/tvcmd"
TVCMD_OPTION="-e"

_userRemoveShow(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
        return 1
    else
        _RAW_SHOW="$*"
        _U_FILE="${HOME}/.config/tvcmd/main.cfg"
        _SHOW="$( echo "${_RAW_SHOW}" | sed -s 's/[[:space:]\.\-]/_/g' )"
        _SHOW_LIST="$( < "${_U_FILE}" grep "shows" | sed -s 's/^shows = //g' )"
        if [[  "${_SHOW_LIST}" =~ ((\,[[:space:]]*)|^)${_SHOW}(((\,)+)|$) ]]; then
            _TMP="tmp$( date +%s ).file"
            < "${_U_FILE}" sed -s "s/${_SHOW}//" | sed "s/, ,/,/g" | sed -s "s/, $//g" | sed -s "s/^,//g" > "${_TMP}" && mv "${_TMP}" "${_U_FILE}" && rm -rf "${_TMP}"
            "${TVCMD_BIN}" "${TVCMD_OPTION}" "update" > /dev/null
        fi
    fi

    return 0
}

_userAddShow(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
        return 1
    else
        _RAW_SHOW="$*"
        _U_FILE="${HOME}/.config/tvcmd/main.cfg"
        _SHOW="$( echo "${_RAW_SHOW}" | sed -s 's/[[:space:]\.\-]/_/g' )"
        _SHOW_LIST="$( < "${_U_FILE}" grep "shows" | sed -s 's/^shows = //g' )"
        if [[  "${_SHOW_LIST}" =~ ((\,[[:space:]]*)|^)${_SHOW}(((\,)+)|$) ]]; then
            echo "present"
        else
            _TMP="tmp$( date +%s ).file"
            < "${_U_FILE}" sed -s "s/shows = ${_SHOW_LIST}/shows = ${_SHOW_LIST}\, ${_SHOW}/" > "${_TMP}" && mv "${_TMP}" "${_U_FILE}" && rm -rf "${_TMP}"
            
            _RES=''
            if _RES="$( ${TVCMD_BIN} ${TVCMD_OPTION} "update" )" ; then
                if ( echo "${_RES}" | grep "${_SHOW} ... OK" ); then
                    echo "${_RES}"
                else
                    _userRemoveShow "${_RAW_SHOW}" > /dev/null
                    echo "not_found"
                    return 3
                fi
            else
                _userRemoveShow "${_RAW_SHOW}" > /dev/null
                echo "fail"
                return 4
            fi
        fi
    fi

    return 0
}

_userCommand(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
        return 1
    else
        yes | ${TVCMD_BIN} ${TVCMD_OPTION} "$*" | sed -e 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g' \
                | sed -e "s/\"/''/g"
        return $?
    fi
}


TVCMD_processUserCommand(){
    if [[ "$#" -lt 1 ]]; then
        echo "fail"
        return 1
    else
        _CMD="$1"
        shift 1

        case "${_CMD}" in
        "ADD_SHOW")
            if [[ "$#" -lt 1 ]]; then
                echo "no-show"
                return 2
            else
                _SHOW="$*"

                _RES=""
                if  ! _RES="$( _userAddShow "${_SHOW}" )"; then
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
                if  ! _RES="$( _userRemoveShow "${_SHOW}" )"; then
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
                if  ! _RES="$( _userCommand "$*" )"; then
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
