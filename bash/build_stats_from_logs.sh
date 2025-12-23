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

PATH_TO_LOGS=/var/log/nginx
PATH_TO_STATS=/var/www/stats.giarrizzo.fr
GLOBAL_INDEX=${PATH_TO_STATS}/index.html
DATE_TODAY_YYYY_MM=$(date '+%Y-%m')
LOG_IGNORE_PATTERN="403|/stats/|192.168.1.|127.0.0."

declare -a WEBSITE_LIST=(
    "bruno.giarrizzo.fr"
    "giarrizzo.fr"
    "hack-with-hyweene.com"
    "jessica.giarrizzo.fr"
    "lyanna.giarrizzo.fr"
    "wedding.giarrizzo.fr"
)

WEBSITE="$1"
ALL_OR_LATEST="$2"

if [ -z "${WEBSITE}" ] || [ -z "${ALL_OR_LATEST}" ]; then
    echo "Usage: $0 <all/website_name> <all/latest>"
    exit 1
fi

if [ "${WEBSITE}" != "all" ]; then
    if [[ ! " ${WEBSITE_LIST[*]} " =~ " ${WEBSITE} " ]]; then
        echo "Error: Website '${WEBSITE}' is not in the predefined list."
        exit 1
    fi
fi

# Vérifie les permissions
if [[ $EUID -ne 0 ]]; then
    echo "Exécuter avec sudo ou en root"
    exit 1
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
        if [ -d "${PATH_TO_STATS}/${WEBSITE_ITEM}" ]; then
            echo "            <li class='site-card'><a href='${WEBSITE_ITEM}'>${WEBSITE_ITEM}</a></li>"
        fi
    done

    echo "        </ul>"
    echo "        <hr />"
    echo "        <p>Généré le $(date '+%Y-%m-%d %H:%M:%S')</p>"
    echo "    </body>"
    echo "</html>"
} > "${GLOBAL_INDEX}"

echo ""
echo "Main index updated at ${GLOBAL_INDEX}."

chown bgiarrizzo:bgiarrizzo "${GLOBAL_INDEX}"

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
    mkdir -p ${PATH_TO_STATS}/${WEBSITE_ITEM}

    echo "Processing log files :"
    echo "  - ${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log"
    echo "  - ${PATH_TO_STATS}/${WEBSITE_ITEM}/*/access.log.gz"

    zcat -f ${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log ${PATH_TO_STATS}/${WEBSITE_ITEM}/*/access.log.gz | \
        grep -Ev ${LOG_IGNORE_PATTERN} | \
        goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
        --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/all-time-no-crawlers.html > /dev/null

    zcat -f ${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log ${PATH_TO_STATS}/${WEBSITE_ITEM}/*/access.log.gz | \
        grep -Ev ${LOG_IGNORE_PATTERN} | \
        goaccess - --log-format=COMBINED \
        --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/all-time-with-crawlers.html > /dev/null

    if [ "${ALL_OR_LATEST}" == "latest" ]; then
        echo ""
        echo "# ---------------------------------------------------"
        echo ""
        echo "Generating ${WEBSITE} latest stats ..."
        echo ""
        echo "Processing log file:"
        echo "  - ${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log"
        echo ""

        mkdir -p ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_TODAY_YYYY_MM}

        zcat -f "${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log" | \
            grep -Ev ${LOG_IGNORE_PATTERN} | \
            goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_TODAY_YYYY_MM}/index.html > /dev/null

        zcat -f "${PATH_TO_LOGS}/${WEBSITE_ITEM}/access.log" | \
            grep -Ev ${LOG_IGNORE_PATTERN} | \
            goaccess - --log-format=COMBINED \
            --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_TODAY_YYYY_MM}/with-crawlers.html /dev/null

        echo ""
        echo "Files generated at ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_TODAY_YYYY_MM}/"
    else
        for FOLDER in ${PATH_TO_STATS}/${WEBSITE_ITEM}/*; do

            if [ -d ${FOLDER} ]; then
                DATE_YYYY_MM=$(basename ${FOLDER})
                
                if [ ${DATE_YYYY_MM} == ${DATE_TODAY_YYYY_MM} ]; then
                    continue
                fi
            else
                continue
            fi

            echo ""
            echo "# ---------------------------------------------------"
            echo ""

            echo "Generating ${WEBSITE} ${DATE_YYYY_MM} stats ..."

            mkdir -p ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}

            echo "Processing log file :"
            echo "  - ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}/access.log.gz"
            echo ""

            zcat -f "${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}/access.log.gz" | \
                grep -Ev ${LOG_IGNORE_PATTERN} | \
                goaccess - --unknowns-as-crawlers --ignore-crawlers --log-format=COMBINED \
                --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}/index.html > /dev/null

            zcat -f "${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}/access.log.gz" | \
                grep -Ev ${LOG_IGNORE_PATTERN} | \
                goaccess - --log-format=COMBINED \
                --exclude-ip=192.168.1.0-192.168.1.255 -o ${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}/with-crawlers.html /dev/null

            chown -R bgiarrizzo:bgiarrizzo "${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}"
        done
    fi

    INDEX_HTML="${PATH_TO_STATS}/${WEBSITE_ITEM}/index.html"

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
        echo "        </style>"
        echo "    </head>"
        echo "    <body>"
        echo "        <h1>Statistiques pour ${WEBSITE_ITEM}</h1>"
        echo "        <hr />"
        echo "        <ul>"
        echo "        <li class='site-card'>All time — <a href='all-time-no-crawlers.html'>sans crawlers</a> / <a href='all-time-with-crawlers.html'>avec crawlers</a></li>"

        for subdir in $(ls -d ${PATH_TO_STATS}/${WEBSITE_ITEM}/*/ 2>/dev/null | sort -r); do
            dirname=$(basename "${subdir}")
            if [ -d "${subdir}" ]; then
                echo "        <li class='site-card'>${dirname} — <a href='${dirname}'>sans crawlers</a> / <a href='${dirname}/with-crawlers.html'>avec crawlers</a></li>"
            fi
        done

        echo "        </ul>"
        echo "        <hr />"
        echo "        <p>Généré le $(date '+%Y-%m-%d %H:%M:%S')</p>"
        echo "    </body>"
        echo "</html>"
    } > "${INDEX_HTML}"

    echo ""
    echo "Stats for ${WEBSITE_ITEM} generated at ${INDEX_HTML}."

    chown -R bgiarrizzo:bgiarrizzo "${PATH_TO_STATS}/${WEBSITE_ITEM}"
done

echo ""
echo "# ---------------------------------------------------"
echo "# ---------------------------------------------------"
echo ""

echo "Done stats generation."
