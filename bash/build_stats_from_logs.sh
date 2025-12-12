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

declare -a WEBSITE_LIST=(
        "hack-with-hyweene.com"
        # Sites
        "giarrizzo.fr" 
        "bruno.giarrizzo.fr" 
        "jessica.giarrizzo.fr" 
        "lyanna.giarrizzo.fr"
        "wedding.giarrizzo.fr" 
        # Outils
        "freshrss.giarrizzo.fr"
        "home.giarrizzo.fr"
        "retroarch.giarrizzo.fr"
        "stats.giarrizzo.fr"
        "wallabag.giarrizzo.fr"
        # Servarr
        "prowlarr.giarrizzo.fr"
        "radarr.giarrizzo.fr"
        "sonarr.giarrizzo.fr"
        "lidarr.giarrizzo.fr"
    )

LOG_IGNORE_PATTERN="403|/stats/|192.168.1.|127.0.0."

WEBSITE="$1"
ALL_OR_LATEST="$2"

if [ -z "${WEBSITE}" ] || [ -z "${ALL_OR_LATEST}" ]; then
    echo "Usage: $0 <all/website_name> <all/latest>"
    exit 1
fi

PATH_TO_LOGS=/var/log/nginx
PATH_TO_STATS=/var/www/stats.giarrizzo.fr
GLOBAL_INDEX=${PATH_TO_STATS}/index.html

if [ "${WEBSITE}" != "all" ]; then
    if [[ ! " ${WEBSITE_LIST[*]} " =~ " ${WEBSITE} " ]]; then
        echo "Error: Website '${WEBSITE}' is not in the predefined list."
        exit 1
    fi
fi

{
    echo "<!DOCTYPE html>"
    echo "<html lang='fr'>"
    echo "    <head>"
    echo "        <meta charset='UTF-8'>"
    echo "        <title>Statistiques globales</title>"
    echo "        <style>"
    echo "              body { font-family: Arial, sans-serif; margin: 40px; background-color: #fafafa; }"
    echo "              h1 { color: #333; }"
    echo "              ul { list-style-type: none; padding: 0; }"
    echo "              li { margin: 10px 0; }"
    echo "              a { text-decoration: none; color: #268bd2; }"
    echo "              a:hover { text-decoration: underline; }"
    echo "              .site-card { background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 8px; box-shadow: 1px 1px 2px rgba(0,0,0,0.05); margin-bottom: 10px; }"
    echo "        </style>"
    echo "    </head>"
    echo "    <body>"
    echo "        <h1>Statistiques globales des sites</h1>"
    echo "        <hr />"
    echo "        <ul>"

    for WEBSITE_ITEM in "${WEBSITE_LIST[@]}"; do
        WEBSITE_ITEM_PATH=${PATH_TO_STATS}/${WEBSITE}
        if [ -f "${WEBSITE_ITEM_PATH}/index.html" ]; then
            echo "            <li class='site-card'><a href='${WEBSITE_ITEM}/index.html'>${WEBSITE_ITEM}</a></li>"
        fi
    done

    echo "        </ul>"
    echo "        <hr />"
    echo "        <p>Généré le $(date '+%Y-%m-%d %H:%M:%S')</p>"
    echo "    </body>"
    echo "</html>"
} > "${GLOBAL_INDEX}"

echo ""
echo "Init stats generation."

for WEBSITE_ITEM in "${WEBSITE_LIST[@]}"; do
    if [ ${WEBSITE} != "all" ]; then
        if [ ${WEBSITE} != ${WEBSITE_ITEM} ]; then
            continue
        fi;
    fi;

    echo ""
    echo "# ---------------------------------------------------"
    echo "# ---------------------------------------------------"
    echo ""
    echo "Generating all-time stats for ${WEBSITE_ITEM}..."
    STATSDIR="${PATH_TO_STATS}/${WEBSITE_ITEM}"
    mkdir -p "${STATSDIR}"

    PATH_TO_WEBSITE_ITEM_LOGS=${PATH_TO_LOGS}/${WEBSITE_ITEM}

    echo "Processing log file: ${PATH_TO_WEBSITE_ITEM_LOGS}/access.log*"

    zcat -f ${PATH_TO_WEBSITE_ITEM_LOGS}/access.log* | \
        grep -Ev ${LOG_IGNORE_PATTERN} | \
        goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
        --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR}/all-time-no-crawlers.html > /dev/null

    zcat -f ${PATH_TO_WEBSITE_ITEM_LOGS}/access.log* | \
        grep -Ev ${LOG_IGNORE_PATTERN} | \
        goaccess - --log-format=COMBINED \
        --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR}/all-time-with-crawlers.html > /dev/null

    for log_file in ${PATH_TO_WEBSITE_ITEM_LOGS}/access.log*; do

        if [ "${ALL_OR_LATEST}" == "latest" ]; then
            if [ "$(basename "$log_file")" != "access.log" ] && [ "$(basename "$log_file")" != "access.log.gz" ]; then
                continue
            fi
        fi

        echo ""
        echo "# ---------------------------------------------------"
        echo ""
        stats_date=$(basename "$log_file" | sed -E 's/access\.log\.([0-9]{4})-([0-9]{2})/\1-\2/' | tr -d '.gz')
        if [ "${stats_date}" == "accesslo" ]; then
            stats_date=$(date +%Y-%m)
        fi

        echo "Generating ${stats_date} stats ..."

        STATSDIR_WITH_DATE=${STATSDIR}/${stats_date}
        mkdir -p "${STATSDIR_WITH_DATE}"

        echo "Processing log file: ${log_file}"

        zcat -f "${log_file}" | \
            grep -Ev ${LOG_IGNORE_PATTERN} | \
            goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR_WITH_DATE}/index.html > /dev/null

        zcat -f "${log_file}" | \
            grep -Ev ${LOG_IGNORE_PATTERN} | \
            goaccess - --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${STATSDIR_WITH_DATE}/with-crawlers.html /dev/null
    done

    INDEX_HTML="${STATSDIR}/index.html"

    {
        echo "<!DOCTYPE html>"
        echo "<html lang='fr'>"
        echo "    <head>"
        echo "        <meta charset='UTF-8'><title>Statistiques pour ${WEBSITE_ITEM}</title>"
        echo "        <style>"
        echo "            body { font-family: Arial, sans-serif; margin: 40px; background-color: #fafafa; }"
        echo "            h1 { color: #333; }"
        echo "            ul { list-style-type: none; padding: 0; }"
        echo "            li { margin: 10px 0; }"
        echo "            a { text-decoration: none; color: #268bd2; }"
        echo "            a:hover { text-decoration: underline; }"
        echo "            .site-card { background: #fff; border: 1px solid #ddd; padding: 15px; border-radius: 8px; box-shadow: 1px 1px 2px rgba(0,0,0,0.05); margin-bottom: 10px; }"
        echo "        <style>"
        echo "    </head>"
        echo "    <body>"
        echo "        <h1>Statistiques pour ${WEBSITE_ITEM}</h1>"
        echo "        <hr />"
        echo "        <ul>"
        echo "        <li class='site-card'>All time — <a href='all-time-no-crawlers.html'>sans crawlers</a> / <a href='all-time-with-crawlers.html'>avec crawlers</a></li>"

        for subdir in $(ls -d ${STATSDIR}/*/ 2>/dev/null | sort -r); do
            dirname=$(basename "${subdir}")
            if [ -f "${subdir}/index.html" ]; then
                echo "        <li class='site-card'>${dirname} — <a href='${dirname}/index.html'>sans crawlers</a> / <a href='${dirname}/with-crawlers.html'>avec crawlers</a></li>"
            fi
        done

        echo "        </ul>"
        echo "        <hr />"
        echo "        <p>Généré le $(date '+%Y-%m-%d %H:%M:%S')</p>"
        echo "    </body>"
        echo "</html>"
    } > "${INDEX_HTML}"
done

echo ""
echo "# ---------------------------------------------------"
echo "# ---------------------------------------------------"
echo ""

echo "Done stats generation."
