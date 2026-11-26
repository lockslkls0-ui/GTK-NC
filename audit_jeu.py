#!/usr/bin/env python3
import os, glob, subprocess, shutil

root = os.path.expanduser("~/Caillou_Survival")
print("\n=== 🛡️ SUPER-AUDIT COMPLET CAILLOU SURVIVAL ===")
ok = True
for gd in sorted(glob.glob(f"{root}/scripts/*.gd")):
    nom = os.path.basename(gd)
    lignes = [l for l in open(gd, encoding="utf-8") if l.strip()]
    if len(lignes) < 6:
        print(f"✘ [ROUGE] {nom:<18} │ FICHIER VIDE OU TRONQUÉ ({len(lignes)} lignes) !")
        ok = False
        continue
    r = subprocess.run(["godot3", "--path", root, "--check-only", "-s", gd], capture_output=True, text=True)
    if r.returncode == 0 and "SCRIPT ERROR" not in r.stderr:
        print(f"✔ [VERT ] {nom:<18} │ {len(lignes)} lignes | Syntaxe & Fonctions OK")
        shutil.copy2(gd, f"{root}/backup_scripts/{nom}")
    else:
        print(f"✘ [ROUGE] {nom} -> {r.stderr.strip()}")
        ok = False
if ok:
    rt = subprocess.run(["godot3", "--path", root, "--quit"], capture_output=True, text=True)
    print("✔ [VERT ] SIMULATION JEU (_ready) : 0 ERREUR !" if "ERROR:" not in rt.stderr else f"✘ [ROUGE] {rt.stderr}")
