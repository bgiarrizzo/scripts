#!/usr/bin/env bash
set -euo pipefail

declare -a WEBSITE_LIST=(
    "hack-with-hyweene.com"
    "giarrizzo.fr" 
    "bruno.giarrizzo.fr" 
    "jessica.giarrizzo.fr" 
    "lyanna.giarrizzo.fr"
    "wedding.giarrizzo.fr"
)

PATH_TO_LOGS="/var/log/nginx"
STATS_DIR="/var/www/stats.giarrizzo.fr"

WEBSITE=$1

if [ -z "${WEBSITE}" ]; then
    echo "Usage: $0 <all/website_name>"
    exit 1
fi

if [ "${WEBSITE}" != "all" ]; then
    if [[ ! " ${WEBSITE_LIST[*]} " =~ " ${WEBSITE} " ]]; then
        echo "Error: Website '${WEBSITE}' is not in the predefined list."
        exit 1
    fi
fi

# Fonction pour extraire YYYY-MM du nom de fichier actuel
extract_filename_date() {
    local filename="$(basename $1)"
    echo "$filename" | grep -o '[0-9]\{4\}-[0-9]\{2\}' || echo ""
}

# Fonction pour obtenir la date de création (mtime) au format YYYY-MM
get_file_creation_month() {
    local file="$1"
    stat -c %Y "$file" 2>/dev/null | xargs -I {} date -d @{} '+%Y-%m' 2>/dev/null || echo ""
}

# Vérifie les permissions
if [[ $EUID -ne 0 ]]; then
    echo "Exécuter avec sudo"
    exit 1
fi

for WEBSITE_ITEM in "${WEBSITE_LIST[@]}"; do
    if [ ${WEBSITE} != "all" ]; then
        if [ ${WEBSITE} != ${WEBSITE_ITEM} ]; then
            continue
        fi;
    fi;

    echo ""
    echo "Traitement de ${WEBSITE_ITEM}"

    # Trie les fichiers par date de modification (plus ancien → plus récent)
    find "${PATH_TO_LOGS}/${WEBSITE_ITEM}" -type f -name "access.log.*" -exec stat -c '%Y %n' {} + | sort -n | cut -d' ' -f2- \
    | while read -r ACCESS_LOG_FILE; do
        echo "Traitement de : ${ACCESS_LOG_FILE}"

        FILE_DATE=$(get_file_creation_month "${ACCESS_LOG_FILE}")
        FILENAME_DATE=$(extract_filename_date "${ACCESS_LOG_FILE}")

        zcat -f -- "${ACCESS_LOG_FILE}" | while IFS= read -r LINE; do
            # Extrait la date de la ligne : [29/Jun/2025:01:36:05 +0200]
            # On ne garde que [DD/Mon/YYYY]
            DATE_MATCH=$(echo "${LINE}" | grep -o '\[[0-9]\{2\}/[A-Za-z]\{3\}/[0-9]\{4\}')

            # Skip si pas de date trouvée
            [[ -z "${DATE_MATCH}" ]] && continue

            DAY=$(echo "${DATE_MATCH}"  | cut -d'[' -f2 | cut -d'/' -f1)
            MONTH=$(echo "${DATE_MATCH}"  | cut -d'/' -f2)
            YEAR=$(echo "${DATE_MATCH}" | cut -d'/' -f3 | tr -d ']')

            case "${MONTH}" in
                Jan) MONTH_NUM="01" ;;
                Feb) MONTH_NUM="02" ;;
                Mar) MONTH_NUM="03" ;;
                Apr) MONTH_NUM="04" ;;
                May) MONTH_NUM="05" ;;
                Jun) MONTH_NUM="06" ;;
                Jul) MONTH_NUM="07" ;;
                Aug) MONTH_NUM="08" ;;
                Sep) MONTH_NUM="09" ;;
                Oct) MONTH_NUM="10" ;;
                Nov) MONTH_NUM="11" ;;
                Dec) MONTH_NUM="12" ;;
                *) continue ;;
            esac

            # Date réelle de la ligne
            DATE_YYYY_MM="${YEAR}-${MONTH_NUM}"

            # Fichier cible basé sur la date de la ligne
            OUT_PATH="${PATH_TO_STATS}/${WEBSITE_ITEM}/${DATE_YYYY_MM}"

            mkdir -p ${OUT_PATH}

            # Append compressé de la ligne dans le bon fichier
            echo "$LINE" | gzip -c >> "${OUT_PATH}/access.log.gz"
        done
    done

    tree "${PATH_TO_LOGS}/${WEBSITE_ITEM}"
done

echo ""
echo "✅ Tri terminé."
