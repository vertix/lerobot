#!/bin/env bash
set -ex

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    return 1
fi

nebius profile create \
    --endpoint api.eu.nebius.cloud \
    --service-account-id $SA_ID \
    --public-key-id $PUBLIC_KEY_ID \
    --private-key-file $PRIVATE_KEY_PATH \
    --profile $SA_PROFILE_NAME \
    --parent-id $NB_PROJECT_ID


sudo cp $SCRIPT_DIR/idle/is_idle.sh /usr/local/bin/is_idle
sudo cp $SCRIPT_DIR/idle/shutown_if_idle.sh /usr/local/bin/shutown_if_idle
sudo cp $SCRIPT_DIR/stop.sh /usr/local/bin/stop_server

# allow current user to use crontab
sudo bash -c "echo \"$USER\" >> /etc/cron.allow"
sudo chmod 666 /etc/cron.allow

# remove system_idle_since file at startup
(crontab -l 2>/dev/null; echo "@reboot rm -f $HOME/.cache/system_idle_since") | crontab -

# add is_idle.sh to crontab every 30 minutes
(crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/is_idle") | crontab -

# add shutown_if_idle.sh to crontab every 1 minute
(crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/shutown_if_idle") | crontab -
