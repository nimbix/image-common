#!/bin/bash
#
# NIMBIX CONFIDENTIAL
# -------------------
#
# Copyright (c) 2016 Nimbix, Inc.  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains the property of
# Nimbix, Inc. and its suppliers, if any.  The intellectual and technical
# concepts contained herein are proprietary to Nimbix, Inc.  and its suppliers
# and may be covered by U.S. and Foreign Patents, patents in process, and are
# protected by trade secret or copyright law.  Dissemination of this
# information or reproduction of this material is strictly forbidden unless
# prior written permission is obtained from Nimbix, Inc.

set -e

. /etc/JARVICE/jobinfo.sh

LOG_PATH="/data/${JOB_NAME}.log"
SCRIPT_PATH="`dirname $0`/dummy-task.sh"
HOSTFILE="/etc/JARVICE/cores"

echo "Initializing Batch Runner: $0 $@" >> ${LOG_PATH}

if [ -r /etc/redhat-release ]; then
    # On CentOS 6, MPI is stored here /usr/lib64/openmpi/bin/mpirun.
    # Adding it to the path is managed by environment-modules. Use module
    # avail to see available modules. openmpi-x86_64 is in
    # /etc/modulefiles
    . /etc/profile.d/modules.sh
    module load openmpi-x86_64 1>&2
fi

# Parse the command line arguments
while [ ! -z "$1" ]; do
    case "$1" in
        -f)
            shift
            FILE_INPUT="$1"
            ;;
        -i)
            shift
            ITERATIONS="$1"
            ;;
        -d)
            shift
            DELAY="$1"
            ;;
        *)
            ;;
    esac
    shift
done

if [ ! -x $SCRIPT_PATH ]; then
    echo "FATAL: $SCRIPT_PATH does not exist!" 1>&2
    exit 1
fi
    
if [ ! -r $FILE_INPUT ]; then
    echo "FATAL: $FILE_INPUT does not exist!" 1>&2
    exit 1
fi

if [ ! -r $HOSTFILE ]; then
    echo "FATAL: $HOSTFILE does not exist!" 1>&2
    exit 1
fi

INPUT_LINES=`cat $FILE_INPUT | wc -l`

echo "$FILE_INPUT contains: $INPUT_LINES lines."

mpirun -hostfile ${HOSTFILE} $SCRIPT_PATH $ITERATIONS $DELAY | tee -a ${LOG_PATH}
