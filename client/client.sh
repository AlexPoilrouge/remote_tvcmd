#!/bin/bash


depend_check() {
    for arg; do
		hash "$arg" 2>/dev/null || { echo "Error: Could not find \"$arg\" application."; exit -1; }
    done    
}

py3_package_check() {
    for arg; do
        python3 -c "import $arg" 2>/dev/null || { echo "Error: Could not find \"$arg\" python package."; exit -1; }
    done
}

echoerr() { echo "$@" 1>&2; }




depend_check "python3"
depend_check "curl"

py3_package_check "json"
py3_package_check "gi, gi.repository.Gtk, gi.repository.GObject, gi.repository.GLib"



SCRIPT_DIR="$( realpath "$( dirname "$0" )" )"

RECIEVER="${SCRIPT_DIR}/reciever.sh"
GUI="${SCRIPT_DIR}/gui/GUI.py"
SENDER="${SCRIPT_DIR}/sender.sh"

FIFO_PATH="${SCRIPT_DIR}/pipe"


trap 'exit 0' INT QUIT TERM;

mkfifo "${FIFO_PATH}" -m700

( "${RECIEVER}" < "${FIFO_PATH}" ) | tee "${SCRIPT_DIR}/log_recieve.txt" | "${GUI}" | ( "${SENDER}" > "${FIFO_PATH}" )

rm -f "${FIFO_PATH}"

exit 0
