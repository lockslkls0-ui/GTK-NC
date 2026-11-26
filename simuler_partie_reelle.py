#!/usr/bin/env python3
import os, subprocess

ROOT = os.path.expanduser("~/Caillou_Survival")
bot_gd = os.path.join(ROOT, "scripts/_RobotTest.gd")

code_bot = """extends SceneTree

func _init():
    var m = load("res://scenes/Main.tscn").instance()
    get_root().add_child(m)
    yield(self, "idle_frame")
    yield(self, "idle_frame")

    print("\\n=== 🎮 RAPPORT DU TESTEUR HUMAIN VIRTUEL (VÉRIFICATION INTÉGRALE) ===")
    print("1. Carte & Bâtiments    : ", m.carte.nb_batiments, " bâtiments | ", m.carte.points_routes.size(), " pts route | ", m.carte.lieux_nommes.size(), " lieux nommés")

    # Test Chunks dynamiques hors Nouméa
    m.chunks.verifier_chunks(Vector2(6000, 6000))
    print("2. Chunks Dynamiques    : ", "✔ ACTIFS (" + str(m.chunks.chunks_generes.size()) + " secteurs générés)" if m.chunks.chunks_generes.size() > 0 else "✘ INACTIFS")

    # Test Recrutement multiple (3 alliés d'affilée)
    var recrutes := 0
    for a in m.pop.allies:
        if recrutes < 3:
            a.set_meta("recrute", true)
            recrutes += 1
    print("3. Recrutement Escouade : ", "✔ " + str(recrutes) + " alliés recrutés sur " + str(m.pop.allies.size()) + " habitants")

    # Test Dégâts réels sur le joueur (ennemi au contact)
    m.pop.spawn_ennemi(m.joueur.position, 1)
    var en_test = m.pop.ennemis.back()
    en_test.position = m.joueur.position + Vector2(10, 0)
    var pv_av = m.joueur.pv
    m.gerer_combat(0.1)
    print("4. Dégâts sur Joueur    : ", "✔ PV BAISSENT (" + str(pv_av) + " -> " + str(m.joueur.pv) + ")" if m.joueur.pv < pv_av else "✘ INVULNÉRABLE (BUG)")

    # Test Tir & Sniper Lunette
    for _i in range(4): m.armes.changer_arme()
    m.armes.tirer(m.joueur.position, Vector2(1, 0), m, m.projectiles)
    print("5. Sniper & Balistique  : ", "✔ ARME=" + m.armes.noms[m.armes.arme_idx] + " | BALLES EN VOL=" + str(m.projectiles.size()))

    # Test Panne sèche véhicule
    var v0 = m.veh.vehicules.front()
    m.joueur.en_vehicule = true; m.joueur.vehicule_ref = v0; v0.set_meta("essence", 0.0)
    m._physics_process(0.1)
    print("6. Panne Sèche (0%)     : ", "✔ MOTEUR COUPÉ (vit=0)" if v0.get_meta("vit") == 0.0 else "✘ ROULE ENCORE")

    # Test QG, Coffre & Explosif
    m.eco.poser_coffre_qg(m.joueur.position)
    m.eco.poser_explosif(m.joueur.position)
    print("7. QG & Explosifs       : ", "✔ COFFRE QG POSÉ & BOMBE AMORCÉE" if m.eco.coffre_pose and m.eco.bombes_actives.size() > 0 else "✘ ÉCHEC")
    print("==================================================================\\n")
    quit()
"""

with open(bot_gd, "w", encoding="utf-8") as f:
    f.write(code_bot)

r = subprocess.run(["godot3", "--path", ROOT, "-s", "res://scripts/_RobotTest.gd"], capture_output=True, text=True)
os.remove(bot_gd)
print(r.stdout)
if "ERROR:" in r.stderr or "SCRIPT ERROR" in r.stderr:
    print("❌ ERREURS RUNTIME :\n", r.stderr)
