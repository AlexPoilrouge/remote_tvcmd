#!/bin/bash


SCRIPT_DIR="$( realpath "$( dirname "$0" )" )"

RECIEVER="${SCRIPT_DIR}/reciever.sh"
GUI="${SCRIPT_DIR}/gui/GUI.py"
SENDER="${SCRIPT_DIR}/sender.sh"

FIFO_PATH="${SCRIPT_DIR}/pipe"


quit(){
    rm -f "${FIFO_PATH}"

    exit 0
}

trap 'quit_cmd' INT QUIT TERM;

mkfifo "${FIFO_PATH}" -m700

( sleep 2; "${RECIEVER}" < "${FIFO_PATH}" ) | tee "${SCRIPT_DIR}/log_recieve.txt" | "${GUI}" | ( "${SENDER}" > "${FIFO_PATH}" )

quit
