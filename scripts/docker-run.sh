docker run --gpus all --shm-size 128G --rm \
    --volume $DATA_DIR:/data \
    --volume $PWD:/lerobot \
    -it positronic/lerobot "$@"
