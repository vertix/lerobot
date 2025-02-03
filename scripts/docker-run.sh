
function ask_and_stop() {
    # Shutdown in 30 seconds if not cancelled
    read -t 30 -p "Shutdown in 30 seconds. Press Ctrl+C to cancel. "
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
