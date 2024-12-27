#!/bin/env bash
set -ex

curl -sSL https://storage.eu-north1.nebius.cloud/cli/install.sh | bash

source $HOME/.bashrc

export NB_PROFILE_NAME=machine
export NB_PROJECT_ID=project-e00f38wexevrr52b8j

export SA_PROFILE_NAME=machine-account
export SA_ID=serviceaccount-e00yej1fwa5jwsh2pn

export PUBLIC_KEY_ID=publickey-e00ghh29tabresa0q1
export PRIVATE_KEY_PATH="$HOME/.nebius_private_key.pem"

if [ ! -f $PRIVATE_KEY_PATH ]; then
    echo "Private key file not found at $PRIVATE_KEY_PATH; Copy your private key to this file."
    exit 1
fi

nebius profile create \
    --endpoint api.eu.nebius.cloud \
    --service-account-id $SA_ID \
    --public-key-id $PUBLIC_KEY_ID \
    --private-key-file $PRIVATE_KEY_PATH \
    --profile $SA_PROFILE_NAME \
    --parent-id $NB_PROJECT_ID
