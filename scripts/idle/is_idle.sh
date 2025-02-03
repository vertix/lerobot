#!/bin/env bash

is_idle() {
    if command -v nvidia-smi &> /dev/null; then
        GPU_USAGE=$(nvidia-smi --query-gpu utilization.gpu --format=csv,noheader,nounits)
    else
        GPU_USAGE=0
    fi

    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
    CPU_IDLE_INT=${CPU_IDLE%.*}

    if [ $GPU_USAGE -lt 10 ] && [ $CPU_IDLE_INT -gt 90 ]; then
        return 0
    else
        return 1
    fi
}

check_and_save_idle_time() {
    IDLE_FILE="$HOME/.cache/system_idle_since"

    if is_idle; then
        # Only save timestamp if file doesn't exist yet
        if [ ! -f "$IDLE_FILE" ]; then
            date +%s > "$IDLE_FILE"
        fi
    else
        # Clear the file if system is not idle
        rm -f "$IDLE_FILE"
    fi
}

check_and_save_idle_time
