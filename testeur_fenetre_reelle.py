#!/usr/bin/env python3
import time, subprocess

print("🤖 Recherche de la fenêtre Caillou Survival...")
wid = subprocess.getoutput("xdotool search --name 'Caillou Survival' | head -n 1").strip()
if not wid:
    print("❌ Fenêtre du jeu non trouvée (lance d'abord le jeu).")
else:
    print(f"✅ Fenêtre trouvée (ID={wid}) — Simulation clavier réelle en cours...")
    subprocess.run(["xdotool", "windowactivate", "--sync", wid])
    for touche in ["d", "d", "s", "Tab", "Tab", "Tab", "Tab", "b", "space", "b", "m"]:
        subprocess.run(["xdotool", "key", "--window", wid, touche])
        time.sleep(0.35)
    print("🏆 Test clavier réel terminé sur la fenêtre ouverte !")
