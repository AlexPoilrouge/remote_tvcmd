#!/bin/bash


SCRIPT_NAME=$( basename "$0" )
SCRIPT_DIR_PATH=$( realpath "$( dirname "$0" )" )

USER_INSTALL_DIR="${HOME}/.remote_tvcmd"
SYSTEM_INSTALL_DIR="/usr/share/remote_tvcmd"

INSTALL_DIR="${USER_INSTALL_DIR}"

USER_APP_DIR="${HOME}/.local/share/applications"
SYSTEM_APP_DIR="/usr/share/applications"

APP_DIR="${USER_APP_DIR}"



echo_desktop_file(){
    echo -e "[Desktop Entry]"
    echo -e "Name=remote_tvcmd"
    echo -e "GenericName=remote_tvcmd"
    echo -e "Icon=tv-symbolic"
    echo -e "Exec=sh ${INSTALL_DIR}/client.sh"
    echo -e "Type=Application"
    echo -e "Terminal=false"
}



 
if ! OPTS=$( getopt -o --system-install -- "$@" );
then
    echo >&2 "OPTS: ${OPTS}"
    echo >&2 "Unexpected error while reading options and commands …"
    exit 1
fi

eval set -- "$OPTS" 
while true ; do
    case "$1" in
    --system-install)
        INSTALL_DIR="${SYSTEM_INSTALL_DIR}"
        APP_DIR="${SYSTEM_APP_DIR}"
        shift
    ;;
    --) shift; break;;
    esac
done

if [[ "${INSTALL_DIR}" == "${SYSTEM_INSTALL_DIR}" ]] && (( EUID != 0 )); then
    echo "${SCRIPT_NAME} - you would need root privilege to install on system"
    exit 1
fi

if [ ! -d ${INSTALL_DIR} ] && ! ( mkdir -p "${INSTALL_DIR}" ) ; then
    echo "${SCRIPT_NAME} - couldn't found nor create directory ${INSTALL_DIR} for installation…"
    exit 2
fi

if [[ "${APP_DIR}" == "${SYSTEM_APP_DIR}" ]] && (( EUID != 0 )); then
    echo "${SCRIPT_NAME} - you would need root privilege to install on system"
    exit 3
fi

if [ ! -d ${APP_DIR} ] && ! ( mkdir -p "${APP_DIR}" ) ; then
    echo "${SCRIPT_NAME} - couldn't found nor create directory ${APP_DIR} for installation…"
    exit 4
fi

mkdir -p "${INSTALL_DIR}"/gui || (echo "error installation: 'mkdir -p ${SCRIPT_DIR_PATH}/gui' failed…"; exit 5)
cp -rvf "${SCRIPT_DIR_PATH}"/{client.sh,reciever.sh,sender.sh} "${INSTALL_DIR}"
cp -rvf "${SCRIPT_DIR_PATH}"/gui/{GUI.py,gui.glade} "${INSTALL_DIR}"/gui

echo_desktop_file > "${APP_DIR}/remote_tvcmd.desktop"

if [[ "${INSTALL_DIR}" == "${SYSTEM_INSTALL_DIR}" ]]; then
    ln -s "usr/bin/remote_tvcmd" "${INSTALL_DIR}/client.sh"
fi

exit 0
