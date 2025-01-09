function ask_and_stop() {
    echo "Shutdown in 30 seconds. Press Ctrl+C to cancel."
    # Start sleep in background
    sleep 30 &
    sleep_pid=$!
    # Wait for sleep to finish
    wait $sleep_pid
    # If sleep completed (wasn't interrupted), run stop script
    if [ $? -eq 0 ]; then
        ./scripts/stop.sh
    fi
}

trap ask_and_stop EXIT SIGTERM

docker run --gpus all --shm-size 128G --rm \
    --volume $DATA_DIR:/data \
    --volume $PWD:/lerobot \
    -it positronic/lerobot "$@"
