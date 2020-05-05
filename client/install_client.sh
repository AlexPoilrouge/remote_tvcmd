#!/bin/bash


SCRIPT_NAME=$( basename "$0" )
SCRIPT_DIR_PATH=$( realpath "$( dirname "$0" )" )

ROOT=""

USER_INSTALL_DIR="${HOME}/.remote_tvcmd"
SYSTEM_INSTALL_DIR="/usr/share/remote_tvcmd"

INSTALL_DIR="${USER_INSTALL_DIR}"

USER_APP_DIR="${HOME}/.local/share/applications"
SYSTEM_APP_DIR="/usr/share/applications"
_SYSTEM_BIN_LINK="/usr/bin/remote_tvcmd"

APP_DIR="${USER_APP_DIR}"

MODE="install"



echo_desktop_file(){
    echo -e "[Desktop Entry]"
    echo -e "Name=remote_tvcmd"
    echo -e "GenericName=remote_tvcmd"
    echo -e "Icon=tv-symbolic"
    echo -e "Exec=sh ${INSTALL_DIR}/client.sh"
    echo -e "Type=Application"
    echo -e "Terminal=false"
}



 
if ! OPTS=$( getopt  -l system,uninstall,root: -o : -- "$@" );
then
    echo >&2 "OPTS: ${OPTS}"
    echo >&2 "Unexpected error while reading options and commands …"
    exit 1
fi

eval set -- "$OPTS" =
while true ; do
    case "$1" in
    --system)
        INSTALL_DIR="${SYSTEM_INSTALL_DIR}"
        APP_DIR="${SYSTEM_APP_DIR}"
        shift
    ;;
    --uninstall)
        MODE="uninstall"
        shift
    ;;
    --root)
        ROOT="$2"
        shift 2
    ;;
    --) shift; break;;
    esac
done

if [[ "${ROOT}${INSTALL_DIR}" == "${ROOT}${SYSTEM_INSTALL_DIR}" ]] && (( EUID != 0 )); then
    echo "${SCRIPT_NAME} - you would need root privilege to ${MODE} on system"
    exit 1
fi

if [ ! -d "${ROOT}${INSTALL_DIR}" ] && ! ( mkdir -p "${ROOT}${INSTALL_DIR}" ) ; then
    echo "${SCRIPT_NAME} - couldn't found nor create directory ${ROOT}${INSTALL_DIR} for ${MODE}…"
    exit 2
fi

if [[ "${ROOT}${APP_DIR}" == "${ROOT}${SYSTEM_APP_DIR}" ]] && (( EUID != 0 )); then
    echo "${SCRIPT_NAME} - you would need root privilege to ${MODE} on system"
    exit 3
fi

if [ ! -d "${ROOT}${APP_DIR}" ] && ! ( mkdir -p "${ROOT}${APP_DIR}" ) ; then
    echo "${SCRIPT_NAME} - couldn't found nor create directory ${ROOT}${APP_DIR} for ${MODE}"
    exit 4
fi

if [[ "${MODE}" == "install" ]]; then
    mkdir -p "${ROOT}${INSTALL_DIR}"/gui || (echo "error installation: 'mkdir -p ${ROOT}${INSTALL_DIR}/gui' failed…"; exit 5)
    cp -rvf "${SCRIPT_DIR_PATH}"/{client.sh,reciever.sh,sender.sh} "${ROOT}${INSTALL_DIR}"
    cp -rvf "${SCRIPT_DIR_PATH}"/gui/{GUI.py,gui.glade} "${ROOT}${INSTALL_DIR}"/gui

    echo_desktop_file > "${ROOT}${APP_DIR}/remote_tvcmd.desktop"

    if [[ "${ROOT}${INSTALL_DIR}" == "${ROOT}${SYSTEM_INSTALL_DIR}" ]]; then
        if ! ( mkdir -p "$( realpath "$( dirname "${ROOT}${_SYSTEM_BIN_LINK}" )" )" ); then
            echo "${SCRIPT_NAME} - could not create or access directory containing link '${ROOT}${_SYSTEM_BIN_LINK}'"
        else
            ln -s "${ROOT}${INSTALL_DIR}/client.sh" "${ROOT}${_SYSTEM_BIN_LINK}"
        fi
    fi
elif [[ "${MODE}" == "uninstall" ]]; then
    if [[ "${ROOT}${INSTALL_DIR}" == "${ROOT}${SYSTEM_INSTALL_DIR}" ]] && [ -f "${ROOT}${_SYSTEM_BIN_LINK}" ]; then
        rm -rvf "${ROOT}${_SYSTEM_BIN_LINK}"
    fi

    rm -rvf "${ROOT}${INSTALL_DIR}" "${ROOT}${APP_DIR}/remote_tvcmd.desktop"
fi

exit 0
