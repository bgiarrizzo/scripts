#!/bin/bash

# Script to pull the latest changes from git repositories in folder recursively
# If updates are found, it pulls the latest changes
# If no updates are found, it exits gracefully
# If there are changes in local repository, it skips pulling to avoid conflicts

set -e

REPOS_DIR="/home/bgiarrizzo/code/"

for repo in $(find "$REPOS_DIR" -type d -name ".git"); do
    REPO_DIR=$(dirname "$repo")
    echo "Processing repository in $REPO_DIR"
    cd "$REPO_DIR" || continue

    STATUS=$(git status --porcelain)
    if [ -n "$STATUS" ]; then
        echo "Local changes detected. Skipping pull to avoid conflicts."
        continue
    fi

    git fetch

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Updates found. Pulling latest changes..."
        git pull --ff-only
    else
        echo "No updates found. Repository is up to date."
    fi
done
