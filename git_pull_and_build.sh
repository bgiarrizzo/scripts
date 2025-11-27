#!/bin/bash

# Script to pull the latest changes from the website Git repository

set -e

declare -a website_list=("giarrizzo.fr" "bruno.giarrizzo.fr" "jessica.giarrizzo.fr" "lyanna.giarrizzo.fr" "wedding.giarrizzo.fr" "hack-with-hyweene.com")

WEBSITE="$1"

if [ -z "${WEBSITE}" ]; then
    echo "Usage: $0 <website_name>"
    exit 1
fi

if [[ ! " ${website_list[*]} " =~ " ${WEBSITE} " ]]; then
    echo "Error: Website '${WEBSITE}' is not in the predefined list."
    exit 1
fi

cd "/home/bgiarrizzo/code/Websites/${WEBSITE}" || exit 1

git fetch

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates found. Pulling latest changes..."
    git pull --ff-only
    make build
else
    echo "No updates found. Repository is up to date."
    exit 0
fi
