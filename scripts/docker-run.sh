function ask_and_stop() {
    echo "Shutdown in 30 seconds. Press Ctrl+C to cancel."
    # Start sleep in background
    sleep 30 &
    sleep_pid=$!
    # Wait for sleep to finish
    wait $sleep_pid
    # If sleep completed (wasn't interrupted), run stop script
    if [ $? -eq 0 ]; then
        /usr/local/bin/stop_server
    fi
}

# check if /usr/local/bin/stop_server exists
if [ ! -f /usr/local/bin/stop_server ]; then
    echo "stop_server not found. Run 'source scripts/setup.sh' first."
    exit 1
fi

trap ask_and_stop EXIT SIGTERM

docker run --gpus all --shm-size 128G --rm \
    --volume $DATA_DIR:/data \
    --volume $PWD:/lerobot \
    -it positronic/lerobot "$@"
