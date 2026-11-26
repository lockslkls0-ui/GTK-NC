#!/usr/bin/env bash
DATE_H=$(date +"%Y-%m-%d_%Hh%M")
BUREAU=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
[ ! -d "$BUREAU" ] && BUREAU="$HOME/Bureau"

OUT_DIR="$BUREAU/Export_Jeu_Caillou_Survival_${DATE_H}"
mkdir -p "$OUT_DIR"

F_CODE="$OUT_DIR/1_INTEGRALITE_SCRIPTS_ET_SCENES_JEU.txt"
F_DOC="$OUT_DIR/2_RAPPORT_ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md"

cp -f "$HOME/Caillou_Survival/RAPPORT_ARCHITECTURE_JEU.md" "$F_DOC"

echo "=== CAILLOU SURVIVAL — INTÉGRALITÉ DU CODE & DES SCÈNES ($DATE_H) ===" > "$F_CODE"
find "$HOME/Caillou_Survival" -type f \( -name "*.gd" -o -name "*.tscn" -o -name "*.godot" -o -name "*.py" -o -name "*.sh" -o -name "*.md" \) | sort | while read -r f; do
    echo -e "\n====================================================================" >> "$F_CODE"
    echo "FICHIER : $f | DATE : $DATE_H" >> "$F_CODE"
    echo -e "====================================================================\n" >> "$F_CODE"
    cat "$f" >> "$F_CODE"
done

echo -e "\n--- 📊 ÉTAT DES DONNÉES CARTOGRAPHIQUES ---" >> "$F_CODE"
ls -lh "$HOME/Caillou_Survival"/*.json 2>/dev/null >> "$F_CODE" || echo "Aucune carte JSON encore générée." >> "$F_CODE"

zenity --info --title="🎮 Suivi Jeu Caillou Survival" \
    --text="✅ Export intégral du projet jeu généré sur ton Bureau !\n\n📂 Dossier : Export_Jeu_Caillou_Survival_${DATE_H}\n• 1_INTEGRALITE_SCRIPTS_ET_SCENES_JEU.txt\n• 2_RAPPORT_ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md" \
    --width=460 2>/dev/null
nemo "$OUT_DIR" >/dev/null 2>&1 &
