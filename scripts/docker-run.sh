
function ask_and_stop() {
    # Shutdown in 30 seconds if not cancelled
    read -t 30 -p "Shutdown in 30 seconds. Press Ctrl+C to cancel. "
    if [ $? -eq 0 ]; then
        ./scripts/stop.sh
    fi
}

trap ask_and_stop EXIT SIGTERM

docker run --gpus all --shm-size 128G --rm \
    --volume $DATA_DIR:/data \
    --volume $PWD:/lerobot \
    -it positronic/lerobot "$@"
