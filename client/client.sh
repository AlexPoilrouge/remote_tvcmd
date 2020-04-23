#!/bin/bash

echoerr() { echo "$@" 1>&2; }

SCRIPT_DIR="$( realpath "$( dirname "$0" )" )"

RECIEVER="${SCRIPT_DIR}/reciever.sh"
GUI="${SCRIPT_DIR}/gui/GUI.py"
SENDER="${SCRIPT_DIR}/sender.sh"

FIFO_PATH="${SCRIPT_DIR}/pipe"


trap 'exit 0' INT QUIT TERM;

mkfifo "${FIFO_PATH}" -m700

( "${RECIEVER}" < "${FIFO_PATH}" ) | tee "${SCRIPT_DIR}/log_recieve.txt" | "${GUI}" | tee "${SCRIPT_DIR}/log_gui.txt" | ( "${SENDER}"| tee "${SCRIPT_DIR}/log_send.txt" > "${FIFO_PATH}" )

rm -f "${FIFO_PATH}"

exit 0
