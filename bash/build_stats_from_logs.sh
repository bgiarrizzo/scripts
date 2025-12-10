#!/bin/bash
# Script to generate web statistics from Nginx access logs using GoAccess
# 
# If "website" argument is "all", it processes all predefined websites.
# If "website" argument is a specific website, it processes only that website.
# If "all/latest" argument is "all", it processes all log files.
# If "all/latest" argument is "latest", it processes only the latest log file.
# 
# -------------------------------------------------------------------------------
# Usage: ./regen_stats_from_logs.sh <website> <all/latest>
# Example: ./regen_stats_from_logs.sh giarrizzo.fr all
#          ./regen_stats_from_logs.sh hack-with-hyweene.com latest
# -------------------------------------------------------------------------------

set -e

PATH_TO_STATS=/var/www/stats.giarrizzo.fr

WEBSITE="$1"
ALL_OR_LATEST="$2"

if [ -z "${WEBSITE}" ] || [ -z "${ALL_OR_LATEST}" ]; then
    echo "Usage: $0 <all/website_name> <all/latest>"
    exit 1
fi

if [ "${WEBSITE}" == "all" ]; then
    declare -a website_list=("giarrizzo.fr" "bruno.giarrizzo.fr" "jessica.giarrizzo.fr" "lyanna.giarrizzo.fr" "wedding.giarrizzo.fr" "hack-with-hyweene.com")
else
    website_list=("${WEBSITE}")
fi

for website in "${website_list[@]}"; do
    echo "# ---------------------------------------------------"
    echo "Regenerating stats for ${website}..."
    STATSDIR="${PATH_TO_STATS}/${website}"

    echo "Creating stats directory if it doesn't exist..."
    mkdir -p "${STATSDIR}"
    echo ""

    for log_file in /var/log/nginx/${website}/access.log*; do

        if [ "${ALL_OR_LATEST}" == "latest" ]; then
            if [ "$(basename "$log_file")" != "access.log" ] && [ "$(basename "$log_file")" != "access.log.gz" ]; then
                continue
            fi
        fi

        echo ""
        echo "# ---------------------------------------------------"
        echo ""
        echo "Extract date from log filename: ${log_file}"
        stats_date=$(basename "$log_file" | sed -E 's/access\.log\.([0-9]{4})-([0-9]{2})/\1-\2/' | tr -d '.gz')
        echo "Extracted date: ${stats_date}"

        if [ "${stats_date}" == "accesslo" ]; then
            stats_date=$(date +%Y-%m)
            echo "Log file is current access log, using current date: ${stats_date}"
        fi

        STATSDIR_WITH_DATE=${STATSDIR}/${stats_date}

        echo "Creating stats subdirectory for date if it doesn't exist..."
        mkdir -p "${STATSDIR_WITH_DATE}"
        echo "Done creating directory: ${STATSDIR_WITH_DATE}"

        echo "Processing log file: ${log_file}"
        
        zcat -f "${log_file}" | \
            grep -Ev "403|/stats/" | \
            goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR_WITH_DATE}/index.html

        zcat -f "${log_file}" | \
            grep -Ev "403|/stats/" | \
            goaccess - --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR_WITH_DATE}/with-crawlers.html
            
        echo "Stats generated at ${STATSDIR_WITH_DATE}/"
    done
done

echo "All stats regenerated."
