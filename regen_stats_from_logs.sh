#!/bin/bash
# Script to regenerate web statistics from Nginx access logs using GoAccess

set -e

declare -a website_list=("giarrizzo.fr" "bruno.giarrizzo.fr" "jessica.giarrizzo.fr" "lyanna.giarrizzo.fr" "wedding.giarrizzo.fr" "hack-with-hyweene.com")

for website in "${website_list[@]}"; do
    echo "# ---------------------------------------------------"
    echo "Regenerating stats for ${website}..."
    STATSDIR="/var/www/${website}/stats"

    echo "Creating stats directory if it doesn't exist..."
    mkdir -p "${STATSDIR}"
    echo ""

    for log_file in /var/log/nginx/${website}/access.log*; do
        echo ""
        echo "# ---------------------------------------------------"
        echo ""
        echo "Extract date from log filename: ${log_file}"
        stats_date=$(basename "$log_file" | sed -E 's/access\.log\.([0-9]{4})-([0-9]{2})/\1-\2/' | tr -d '.gz')
        echo "Extracted date: ${stats_date}"

        echo "Creating stats subdirectory for date if it doesn't exist..."
        mkdir -p "${STATSDIR}/${stats_date}"
        echo "Done creating directory: ${STATSDIR}/${stats_date}"

        echo "Processing log file: ${log_file}"
        zcat -f "${log_file}" | grep -Ev "403|/stats/" | goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED --exclude-ip=192.168.1.0-192.168.1.255 -o /var/www/${website}/stats/${stats_date}/index.html
        echo "Stats generated at /var/www/${website}/stats/${stats_date}/index.html"
    done
done

echo "All stats regenerated."