extends Node2D

var pnj_actuel : Node2D = null
var civils_mission := []
var dialogue_actif := false
var lignes_dialogue := [
    "🗣️ Chef de secteur : « La route vers le Ouen Toro est coupée ! Va sécuriser le relais et ramène les survivants. »",
    "🗣️ Médecin de garde : « On manque de carburant à l'Anse Vata. Trouve la station et tiens la position 25 secondes ! »",
    "🗣️ Pilote du lagon : « Des civils sont bloqués près de la Baie des Citrons. Escorte-les jusqu'ici, je te paie 1500 F ! »",
    "🗣️ Mécanicien de brousse : « Le convoi pour Koné attend ton feu vert. Nettoie le périmètre et récupère les caisses ! »"
]

func creer_pnj_mission(pos : Vector2):
    if pnj_actuel != null:
        pnj_actuel.queue_free()
    pnj_actuel = Node2D.new()
    pnj_actuel.position = pos + Vector2(60, 0)
    pnj_actuel.z_index = 6
    var veste = Polygon2D.new()
    veste.polygon = PoolVector2Array([Vector2(-12,-18), Vector2(12,-18), Vector2(12,18), Vector2(-12,18)])
    veste.color = Color(1.0, 0.55, 0.05)
    pnj_actuel.add_child(veste)
    var tete = Polygon2D.new()
    tete.polygon = PoolVector2Array([Vector2(-8,-9), Vector2(9,-9), Vector2(9,9), Vector2(-8,9)])
    tete.color = Color(0.92, 0.76, 0.62)
    pnj_actuel.add_child(tete)
    add_child(pnj_actuel)

func spawner_civils_a_secourir(pos : Vector2, nb : int):
    for c in civils_mission:
        c.queue_free()
    civils_mission.clear()
    for i in range(nb):
        var civ = KinematicBody2D.new()
        civ.position = pos + Vector2(rand_range(-80, 80), rand_range(-80, 80))
        civ.z_index = 6
        var v = Polygon2D.new()
        v.polygon = PoolVector2Array([Vector2(-10,-16), Vector2(10,-16), Vector2(10,16), Vector2(-10,16)])
        v.color = Color(0.95, 0.85, 0.25)
        civ.add_child(v)
        civ.set_meta("sauve", false)
        add_child(civ)
        civils_mission.append(civ)

func obtenir_dialogue(num_mission : int) -> String:
    return lignes_dialogue[num_mission % lignes_dialogue.size()]
