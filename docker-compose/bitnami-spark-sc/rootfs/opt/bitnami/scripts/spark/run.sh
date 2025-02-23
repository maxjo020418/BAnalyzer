#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

# Load libraries
. /opt/bitnami/scripts/libspark.sh
. /opt/bitnami/scripts/libos.sh

# Load Spark environment settings
. /opt/bitnami/scripts/spark-env.sh

if [ "$SPARK_MODE" == "master" ]; then
    # Master constants
    EXEC=$(command -v start-master.sh)
    ARGS=()
    info "** Starting Spark in master mode **"
elif [ "$SPARK_MODE" == "master-connect" ]; then
    # Master w/ spark connect
    MASTER_EXEC=$(command -v start-master.sh)
    MASTER_ARGS=()
    CONNECT_EXEC="/opt/bitnami/spark/sbin/start-connect-server.sh"
    CONNECT_ARGS=("--packages" "org.apache.spark:spark-connect_$SC_VERSION:$APP_VERSION")
    info "** Starting Spark in master mode w/ Connect Server **"
else
    # Worker constants
    EXEC=$(command -v start-worker.sh)
    ARGS=("$SPARK_MASTER_URL")
    info "** Starting Spark in worker mode **"
fi

if am_i_root; then
    if [ "$SPARK_MODE" == "master-connect" ]; then
        exec_as_user "$SPARK_DAEMON_USER" "$MASTER_EXEC" "${MASTER_ARGS[@]}" &
        exec_as_user "$SPARK_DAEMON_USER" "$CONNECT_EXEC" "${CONNECT_ARGS[@]}"
    else
        exec_as_user "$SPARK_DAEMON_USER" "$EXEC" "${ARGS[@]-}"
    fi
else
    if [ "$SPARK_MODE" == "master-connect" ]; then
        "$MASTER_EXEC" "${MASTER_ARGS[@]}" &
        exec "$CONNECT_EXEC" "${CONNECT_ARGS[@]}"
    else
        exec "$EXEC" "${ARGS[@]-}"
    fi
fi

