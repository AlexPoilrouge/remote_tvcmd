#!/bin/bash


echoerr() { echo "$@" 1>&2; }

depend_check() {
    for arg; do
		hash "$arg" 2>/dev/null || { echoerr "Error: Could not find \"$arg\" application."; exit 255; }
    done    
}

py3_package_check() {
    for arg; do
        python3 -c "import $arg" 2>/dev/null || { echoerr "Error: Could not find \"$arg\" python package."; exit 255; }
    done
}


depend_check "python3"
depend_check "curl"

py3_package_check "json"
py3_package_check "gi, gi.repository.Gtk, gi.repository.GObject, gi.repository.GLib"



SCRIPT_DIR="$( realpath "$( dirname "$0" )" )"

RECIEVER="${SCRIPT_DIR}/reciever.sh"
GUI="${SCRIPT_DIR}/gui/GUI.py"
SENDER="${SCRIPT_DIR}/sender.sh"

FIFO_PATH="pipe"

WORK_DIR="${HOME}/.remote_tvcmd"


if [ ! -d "${WORK_DIR}" ] && ! ( mkdir -p "${HOME}/.remote_tvcmd" ); then
    echoerr "Can't found nor create work dir ${WORK_DIR}…"
    exit 1
fi

cd "${WORK_DIR}" || ( echoerr "couldn't access work directory ${WORK_DIR}…"; exit 2)


trap 'exit 0' INT QUIT TERM;

mkfifo "${FIFO_PATH}" -m700

( "${RECIEVER}" < "${FIFO_PATH}" ) | tee "log_recieve.txt" | "${GUI}" | ( "${SENDER}" > "${FIFO_PATH}" )

rm -f "${FIFO_PATH}"

exit 0
