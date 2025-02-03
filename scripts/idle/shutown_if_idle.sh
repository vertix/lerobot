#!/bin/env bash

IDLE_FILE="$HOME/.cache/system_idle_since"

if [ -f "$IDLE_FILE" ]; then
    IDLE_SINCE=$(cat "$IDLE_FILE")
    CURRENT_TIME=$(date +%s)
    IDLE_DURATION=$((CURRENT_TIME - IDLE_SINCE))

    # 4 hours = 14400 seconds
    if [ $IDLE_DURATION -gt 14400 ]; then
        SHUTDOWN_CMD="/usr/local/bin/stop_server"
        $SHUTDOWN_CMD
    fi
fi
