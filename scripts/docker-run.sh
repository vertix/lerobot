docker run --gpus all --rm \
    --volume $DATA_DIR:/data \
    --volume $PWD:/lerobot \
    -it positronic/lerobot "$@"
