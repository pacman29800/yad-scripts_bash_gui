#!/bin/bash
# ==============================================================================
# Script : BD converter - Conversion PDF → CBZ/CBR avec interface YAD
# Version : v1.0.0
# Auteur  : DPMW (pacman29800)
# Date    : 2025
# Licence : MIT 
# ==============================================================================
#
# 🔹 Résumé :
# BD convert est un convertisseur de bandes dessinées ou documents PDF en archives
# CBZ ou CBR, avec interface graphique YAD (Yet Another Dialog) et gestion de
# la progression. Il offre un traitement par page, renommage automatique des
# images, possibilité de conserver ou supprimer les PDF originaux, et journalisation
# des opérations.
#
# 🔹 Fonctionnalités principales :
# - Conversion PDF → images (JPEG, PNG, TIFF) via pdftoppm.
# - Regroupement des images en archives CBZ (ZIP) ou CBR (RAR).
# - Renommage automatique des images (0001-0010.ext).
# - Gestion de la progression et annulation via YAD.
# - Option de log détaillé des étapes.
# - Contrôle thermique pour limiter la charge CPU.
# - Nettoyage automatique des fichiers temporaires.
#
# 🔹 Dépendances :
# - yad       : interface graphique (dialogs, progress bars)
# - pdftoppm  : extraction de pages PDF en images
# - pdfinfo   : calcul du nombre de pages PDF
# - zip       : création d'archives CBZ
# - rar       : création d'archives CBR
# - sensors   :  pour contrôle température CPU
#
# 🔹 Options disponibles via interface YAD :
# - Conserver ou supprimer les PDF originaux
# - Activer ou désactiver le log
# - Choisir la résolution DPI (100–600)
# - Choisir le format image (JPEG, PNG, TIFF)
# - Choisir le format archive (CBZ ou CBR)
# - Sélection du répertoire de sortie
#
# 🔹 Licence :
# - MIT License (DPMW-2025-License MIT)
#   Permet l'utilisation, la modification et la redistribution du script,
#   à condition de conserver ce header et la licence.
#
# 🔹 Notes importantes :
# - Le script vérifie que toutes les dépendances sont présentes avant de
#   commencer la conversion.
# - La progression est affichée à l'utilisateur, et il peut annuler à tout moment.
# - Les logs détaillés sont optionnels et peuvent être sauvegardés dans le
#   répertoire de sortie.
# - Les noms de fichiers images sont normalisés pour une lecture correcte
#   dans les visionneuses CBZ/CBR.
#
# 🔹 Notes :
# - J'ai essayé d'utiliser le parallélisme pour exploiter plusieurs cœurs CPU.
#   Cependant, comme ce script est avant tout visuel, cela créait des conflits
#   avec les fenêtres graphiques. 
#   En raison de ces limitations, le script ne fonctionne que sur un seul cœur.
#
# - 2025 : Version finale corrigée avec annulation et fenêtre pulsante lors
#   de la création d'archives.
#
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# 🔍 Dépendances
REQUIRED_CMDS=(yad pdftoppm pdfinfo zip rar sensors)
MISSING=()
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done
if (( ${#MISSING[@]} )); then
    yad --error --title="Dépendances manquantes" \
        --text="Commandes requises absentes : ${MISSING[*]}" --center
    exit 1
fi

# ⚙️ Options par défaut
KEEP_PDF="FALSE"
ENABLE_LOG="FALSE"
RESOLUTION="200"
IMG_FORMAT="jpeg"
ARCHIVE_FORMAT="CBZ"
OUTPUT_DIR="$HOME"
EXT="${IMG_FORMAT,,}"
[[ "$EXT" == "jpeg" ]] && EXT="jpg"

# 🧩 Texte ASCII et commentaire
BDCONVERT_ASCII="<span foreground='green' font='Monospace bold 12'>

▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
██░▄▄▀██░▄▄▀███▀▄▀█▀▄▄▀█░▄▄▀█▀███▀█░▄▄█░▄▄▀█▄░▄█░▄▄█░▄▄▀
██░▄▄▀██░██░███░█▀█░██░█░██░██░▀░██░▄▄█░▀▀▄██░██░▄▄█░▀▀▄
██░▀▀░██░▀▀░████▄███▄▄██▄██▄███▄███▄▄▄█▄█▄▄██▄██▄▄▄█▄█▄▄
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
_______________________________________dpmw-MIT-v1.0.0__
</span>"
COMMENTAIRE="<span font='Monospace 10'>
💡 Conseil : 

- Pour les BD, privilégiez 200-300 DPI et format JPEG 
pour un bon compromis qualité/taille. 
- Fonctionne sur un seul cœur CPU ; évitez le multi-dossier si possible.
______________________________________________________________________
</span>"

# 📝 Fenêtre principale
OPTIONS=$(yad --form \
    --title="BD converter - Conversion PDF → CBZ/CBR" \
    --width=500 --height=520 --center \
    --text="$BDCONVERT_ASCII\n$COMMENTAIRE" \
    --field="Conserver PDF originaux:CHK" "$KEEP_PDF" \
    --field="Activer le log:CHK" "$ENABLE_LOG" \
    --field="Résolution DPI:NUM" "$RESOLUTION!100..600!50" \
    --field="Format image:CB" 'jpeg!png!tiff' \
    --field="Format archive:CB" 'CBZ!CBR' \
    --field="Répertoire de sortie:DIR" "$OUTPUT_DIR")

[[ -z "$OPTIONS" ]] && exit 0

KEEP_PDF=$(echo "$OPTIONS" | cut -d'|' -f1)
ENABLE_LOG=$(echo "$OPTIONS" | cut -d'|' -f2)
RESOLUTION=$(echo "$OPTIONS" | cut -d'|' -f3)
IMG_FORMAT=$(echo "$OPTIONS" | cut -d'|' -f4)
ARCHIVE_FORMAT=$(echo "$OPTIONS" | cut -d'|' -f5)
OUTPUT_DIR=$(echo "$OPTIONS" | cut -d'|' -f6)
EXT="${IMG_FORMAT,,}"
[[ "$EXT" == "jpeg" ]] && EXT="jpg"

DELETE_ORIGINAL="FALSE"
[[ "$KEEP_PDF" == "FALSE" ]] && DELETE_ORIGINAL="TRUE"

# 📄 Sélection des PDFs
FILES=$(yad --file --title="Sélectionnez les fichiers PDF" \
             --file-filter="*.pdf *.PDF" --multiple --separator="|" --center)
[[ -z "$FILES" ]] && exit 0
IFS="|" read -r -a FILE_ARRAY <<< "$FILES"

# 🔢 Nombre total de pages
get_page_count() { pdfinfo "$1" 2>/dev/null | awk '/^Pages:/ {print $2}'; }
TOTAL_PAGES=0
declare -A PAGES_PER_FILE
for f in "${FILE_ARRAY[@]}"; do
    pages=$(get_page_count "$f")
    pages=${pages:-0}
    PAGES_PER_FILE["$f"]=$pages
    TOTAL_PAGES=$((TOTAL_PAGES + pages))
done
[[ $TOTAL_PAGES -eq 0 ]] && { yad --error --text="Aucune page détectée." --center; exit 1; }

# ⚡ Contrôle thermique (CPU)
TEMP_LIMIT=75
CHECK_INTERVAL=5
check_temp() {
    local temp=50
    if command -v sensors &>/dev/null; then
        temp=$(sensors | awk '/^Package id 0:/{print $4}' | tr -d '+°C')
        temp=${temp%.*}
    elif [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        temp=$(( $(< /sys/class/thermal/thermal_zone0/temp) / 1000 ))
    fi
    echo "$temp"
}

# 🏗 Conversion PDF → images
TEMPDIR_GLOBAL=$(mktemp -d)
LOGFILE=""
if [[ "$ENABLE_LOG" == "TRUE" ]]; then
    LOGFILE=$(mktemp)
fi

PAGE_COUNTER=0
convert_pdf_page() {
    local pdf="$1" page="$2" dest="$3"
    while (( $(check_temp) > TEMP_LIMIT )); do sleep "$CHECK_INTERVAL"; done
    pdftoppm -"$IMG_FORMAT" -r "$RESOLUTION" -f "$page" -l "$page" "$pdf" "$dest/page-$(printf '%04d' "$page")"
    if [[ "$ENABLE_LOG" == "TRUE" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $pdf : page $page convertie" >> "$LOGFILE"
    fi
}

export -f convert_pdf_page check_temp
export IMG_FORMAT RESOLUTION EXT TEMP_LIMIT CHECK_INTERVAL LOGFILE ENABLE_LOG

# 🔄 Conversion avec barre de progression et annulation possible
(
for f in "${FILE_ARRAY[@]}"; do
    BASENAME="$(basename "$f" .pdf)"
    DEST_DIR="$TEMPDIR_GLOBAL/$BASENAME"
    mkdir -p "$DEST_DIR"
    pages=${PAGES_PER_FILE["$f"]}
    for ((i=1; i<=pages; i++)); do
        convert_pdf_page "$f" "$i" "$DEST_DIR"
        PAGE_COUNTER=$((PAGE_COUNTER+1))
        PERCENT=$(( PAGE_COUNTER * 100 / TOTAL_PAGES ))
        echo "$PERCENT"
        echo "# Conversion $BASENAME : page $i/$pages"
    done
done
) | yad --progress --title="Conversion PDF → CBZ/CBR" \
         --width=650 --height=180 \
         --center \
         --auto-close \
         --button=gtk-cancel:1 \
         --text="Démarrage..." \
         --progress-text="Traitement..." \
         --percentage=0 &
YAD_PID=$!
wait $YAD_PID || { yad --info --text="Conversion annulée par l'utilisateur." --center; rm -rf "$TEMPDIR_GLOBAL"; exit 1; }

# ⏳ Fenêtre pulsante pendant création archives avec annulation
yad --progress \
    --title="Veuillez patienter" \
    --width=400 --height=120 \
    --center \
    --auto-close \
    --pulsate \
    --no-percentage \
    --text="Création des archives, veuillez patienter..." \
    --progress-text=" " \
    --button=gtk-cancel:1 &
WAIT_PID=$!

# 🗜 Création archives CBZ/CBR et renommage
shopt -s nullglob
CREATED=()

for f in "$TEMPDIR_GLOBAL"/*; do
    # Vérification annulation
    if ! kill -0 "$WAIT_PID" 2>/dev/null; then
        yad --info --text="Création des archives annulée." --center
        rm -rf "$TEMPDIR_GLOBAL"
        exit 1
    fi

    BASENAME="$(basename "$f")"
    OUTFILE="$OUTPUT_DIR/${BASENAME}.${ARCHIVE_FORMAT,,}"
    [[ -f "$OUTFILE" ]] && rm -f "$OUTFILE"

    IMAGES=( "$f"/*."$EXT" )
    TOTAL=${#IMAGES[@]}
    idx=1
    for img in "${IMAGES[@]}"; do
        newname="$(printf '%03d-%03d.%s' "$idx" "$TOTAL" "$EXT")"
        mv "$img" "$f/$newname"
        if [[ "$ENABLE_LOG" == "TRUE" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - renommage $newname" >> "$LOGFILE"
        fi
        ((idx++))
    done

    if [[ "$ARCHIVE_FORMAT" == "CBZ" ]]; then
        (cd "$f" && zip -q -r "$OUTFILE" .)
        [[ "$ENABLE_LOG" == "TRUE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - Archive CBZ créée : $OUTFILE" >> "$LOGFILE"
    else
        (cd "$f" && rar a -ep1 -inul "$OUTFILE" .)
        [[ "$ENABLE_LOG" == "TRUE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - Archive CBR créée : $OUTFILE" >> "$LOGFILE"
    fi

    CREATED+=("$OUTFILE")

    if [[ "$DELETE_ORIGINAL" == "TRUE" ]]; then
        PDF_ORIGINAL="$OUTPUT_DIR/$BASENAME.pdf"
        [[ -f "$PDF_ORIGINAL" ]] && rm -f "$PDF_ORIGINAL"
        [[ "$ENABLE_LOG" == "TRUE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - PDF original supprimé : $PDF_ORIGINAL" >> "$LOGFILE"
    fi
done

# 🔹 Fermer la fenêtre pulsante
kill "$WAIT_PID" 2>/dev/null

# 🔹 Nettoyage temporaire
rm -rf "$TEMPDIR_GLOBAL"

# 🏁 Bilan final (sans annulation possible)
SUCCESS=${#CREATED[@]}
FAIL=0
yad --info --title="Bilan de conversion" --width=500 --center \
    --text="✅ Succès : $SUCCESS fichier(s)\n❌ Échecs : $FAIL fichier(s)"

# 💾 Proposition de sauvegarde du log
if [[ "$ENABLE_LOG" == "TRUE" && -s "$LOGFILE" ]]; then
    yad --question --title="Sauvegarder le log ?" \
        --text="Voulez-vous enregistrer le fichier log ?" \
        --button="Oui:0" --button="Non:1" --center
    if [[ $? -eq 0 ]]; then
        SAVE_PATH="$OUTPUT_DIR/conversion.log"
        cp "$LOGFILE" "$SAVE_PATH"
        yad --info --title="Log sauvegardé" \
            --text="Fichier log enregistré :\n$SAVE_PATH" --center
    fi
    rm -f "$LOGFILE"
fi

exit 0
