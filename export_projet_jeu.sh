#!/usr/bin/env bash
DATE_H=$(date +"%Y-%m-%d_%Hh%M")
sed -i "s/Dernière mise à jour :.*/Dernière mise à jour : $DATE_H/" "$HOME/Caillou_Survival/RAPPORT_ARCHITECTURE_JEU.md" 2>/dev/null || true
BUREAU=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
[ ! -d "$BUREAU" ] && BUREAU="$HOME/Bureau"

OUT_DIR="$BUREAU/Export_Jeu_Caillou_Survival_${DATE_H}"
mkdir -p "$OUT_DIR"

F_CODE="$OUT_DIR/1_INTEGRALITE_SCRIPTS_ET_SCENES_JEU.txt"
F_DOC="$OUT_DIR/2_RAPPORT_ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md"

cp -f "$HOME/Caillou_Survival/RAPPORT_ARCHITECTURE_JEU.md" "$F_DOC"
F_JOUR="$OUT_DIR/3_JOURNAL_CONVERSATIONS_ET_CONTEXTE_IA.md"
J_MASTER="$HOME/Caillou_Survival/JOURNAL_IA.md"
echo -e "\n### 🗓️ Session du $DATE_H" >> "$J_MASTER"
git -C "$HOME/Caillou_Survival" log -n 5 --oneline >> "$J_MASTER" 2>/dev/null || true
if command -v xclip >/dev/null 2>&1; then
    CLIP=$(xclip -o -selection clipboard 2>/dev/null || true)
    if [ -n "$CLIP" ]; then
        echo -e "\n#### 💬 Conversation enregistrée ($DATE_H) :\n$CLIP\n" >> "$J_MASTER"
    fi
fi
cp -f "$J_MASTER" "$F_JOUR"


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
    --text="✅ Export intégral du projet jeu généré sur ton Bureau !\n\n📂 Dossier : Export_Jeu_Caillou_Survival_${DATE_H}\n• 1_INTEGRALITE_SCRIPTS_ET_SCENES_JEU.txt\n• 2_RAPPORT_ARCHITECTURE_ET_FEUILLE_DE_ROUTE.md\n• 3_JOURNAL_CONVERSATIONS_ET_CONTEXTE_IA.md (Contexte IA + Conversations)" \
    --width=460 2>/dev/null
nemo "$OUT_DIR" >/dev/null 2>&1 &
