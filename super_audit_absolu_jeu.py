#!/usr/bin/env python3
import os, re, glob, json, shutil, subprocess

ROOT = os.path.expanduser("~/Caillou_Survival")
V, R, J, C, Z = "\033[92m", "\033[91m", "\033[93m", "\033[96m", "\033[0m"
verts, jaunes, rouges = 0, 0, 0

def ok(cat, msg):
    global verts; verts += 1
    print(f"  {V}✔ [VERT ]{Z} {cat:<16} │ {msg}")

def err(cat, msg, chemin="", fix="", extrait=""):
    global rouges; rouges += 1
    print(f"  {R}✘ [ROUGE]{Z} {cat:<16} │ {msg}")
    if chemin:  print(f"             ↳ {J}Chemin :{Z} {chemin}")
    if extrait: print(f"             ↳ {J}Code   :{Z} {extrait}")
    if fix:     print(f"             ↳ {C}Fix    :{Z} {fix}")

print(f"\n{C}╔══════════════════════════════════════════════════════════════════════════════╗{Z}")
print(f"{C}║  🔬 SUPER-AUDIT ABSOLU CAILLOU SURVIVAL : CODE, CARTE NC, AUDIO & RUNTIME    ║{Z}")
print(f"{C}╚══════════════════════════════════════════════════════════════════════════════╝{Z}")

print(f"\n{C}▶ [1/4] ARBORESCENCE, DONNÉES CARTOGRAPHIQUES & BRUITAGES (.WAV){Z}")
for d in ["scripts", "scenes", "sons", "backup_scripts"]:
    p = os.path.join(ROOT, d)
    if os.path.isdir(p): ok("Dossier", f"{d}/ présent")
    else: err("Dossier", f"{d}/ manquant", p, f"mkdir -p {p}")

carte_p = os.path.join(ROOT, "carte_noumea.json")
if os.path.exists(carte_p) and os.path.getsize(carte_p) > 10000:
    nb_el = len(json.load(open(carte_p, encoding="utf-8")).get("elements", []))
    ok("Carte OSM NC", f"carte_noumea.json valide ({nb_el} bâtiments & routes)")
else:
    err("Carte OSM NC", "carte_noumea.json absent ou vide", carte_p, "Relancer aspiration Overpass")

for wav in ["tir.wav", "boom.wav", "ok.wav"]:
    wp = os.path.join(ROOT, "sons", wav)
    if os.path.exists(wp) and os.path.getsize(wp) > 100: ok("Audio WAV", f"{wav} ({os.path.getsize(wp)} octets)")
    else: err("Audio WAV", f"{wav} manquant", wp, "Régénérer bruitages Python")

print(f"\n{C}▶ [2/4] COMPILATION INTÉGRALE DES 12 MODULES GDSCRIPT (GODOT 3.5){Z}")
scripts_gd = sorted(glob.glob(f"{ROOT}/scripts/*.gd"))
for gd in scripts_gd:
    nom = os.path.basename(gd)
    lignes = open(gd, encoding="utf-8").readlines()
    non_vides = [l for l in lignes if l.strip()]
    if len(non_vides) < 6:
        err("Fichier Vide", f"{nom} tronqué ({len(non_vides)} lignes)", gd, f"cp -f {ROOT}/backup_scripts/{nom} {gd}")
        continue
    r = subprocess.run(["godot3", "--path", ROOT, "--check-only", "-s", gd], capture_output=True, text=True)
    if r.returncode == 0 and "SCRIPT ERROR" not in r.stderr:
        ok("GDScript", f"{nom:<18} ({len(non_vides)} lignes)")
        shutil.copy2(gd, f"{ROOT}/backup_scripts/{nom}")
    else:
        m = re.search(r':(\d+)\)', r.stderr)
        ln = int(m.group(1)) if m else 0
        ext = f"Ligne {ln}: {lignes[ln-1].strip()}" if 0 < ln <= len(lignes) else r.stderr.strip().splitlines()[0]
        err("GDScript", f"Erreur de syntaxe dans {nom}", gd, f"Corriger ligne {ln} dans {gd}", ext)

print(f"\n{C}▶ [3/4] VÉRIFICATION DES SCÈNES & CONFIGURATION PROJET{Z}")
for f_req in ["project.godot", "scenes/Main.tscn"]:
    fp = os.path.join(ROOT, f_req)
    if os.path.exists(fp) and os.path.getsize(fp) > 10: ok("Config Godot", f"{f_req} OK")
    else: err("Config Godot", f"{f_req} manquant", fp)

print(f"\n{C}▶ [4/4] SIMULATION RUNTIME EN DIRECT (GODOT --QUIT){Z}")
if rouges == 0:
    rt = subprocess.run(["godot3", "--path", ROOT, "--quit"], capture_output=True, text=True)
    if "ERROR:" in rt.stderr or "SCRIPT ERROR" in rt.stderr:
        err("Runtime Godot", rt.stderr.strip().splitlines()[0], f"{ROOT}/scripts/Main.gd")
    else:
        ok("Runtime Godot", "Initialisation complète (_ready + carte + audio + HUD) : 0 ERREUR")
else:
    err("Runtime Godot", "Ignoré tant que les erreurs de compilation ci-dessus ne sont pas corrigées")

tot = verts + rouges
pct = int((verts / tot) * 100) if tot else 0
print(f"\n{C}╔══════════════════════════════════════════════════════════════════════════════╗{Z}")
print(f"{C}║  🏆 BILAN SUPER-AUDIT JEU : {V}✔ VERT: {verts:<3}{Z} │ {R}✘ ROUGE: {rouges:<3}{Z} │ {C}FIABILITÉ: {pct}%{Z}       ║{Z}")
print(f"{C}╚══════════════════════════════════════════════════════════════════════════════╝{Z}\n")
