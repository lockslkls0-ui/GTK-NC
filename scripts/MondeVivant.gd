extends Node2D

var trafic_autos := []
var mission_titre := ""
var mission_type := "tribu"
var mission_cible := Vector2.ZERO
var mission_lieu_nom := "Tribu de Néâria (Houaïlou)"
var mission_pnj_nom := "Coutumier Téin"
var mission_action_faite := false
var mission_bois_depart := 0
var mission_chrono := 0.0
var mission_num := 1
var points_radar := []
var reseau_routes := []
var lieux_reels_carte := []
var pois_reels := []
var balise_sol : Polygon2D
var fleche_boussole : Polygon2D
var eclaireur_pnj : Node2D
var eclaireur_actif := false

func gps_vers_jeu(lat : float, lon : float) -> Vector2:
    var lat0 := -22.3015
    var lon0 := 166.4410
    var echelle := 1650000.0
    return Vector2((lon - lon0) * echelle * cos(deg2rad(lat0)), -(lat - lat0) * echelle)

func initialiser_trafic(pts_routes : Array, lieux_carte : Array = [], liste_pois : Array = []):
    lieux_reels_carte = lieux_carte
    reseau_routes = pts_routes
    pois_reels = liste_pois
    var pos_depart := gps_vers_jeu(-21.2652, 165.6159)
    var p_main = get_parent()
    if p_main != null and p_main.joueur != null:
        p_main.joueur.position = pos_depart

    balise_sol = Polygon2D.new()
    balise_sol.polygon = PoolVector2Array([Vector2(-65,-65), Vector2(65,-65), Vector2(65,65), Vector2(-65,65)])
    balise_sol.color = Color(1.0, 0.85, 0.12, 0.45)
    balise_sol.z_index = 25
    add_child(balise_sol)

    fleche_boussole = Polygon2D.new()
    fleche_boussole.polygon = PoolVector2Array([Vector2(56,-14), Vector2(92,0), Vector2(56,14)])
    fleche_boussole.color = Color(1.0, 0.88, 0.15)
    fleche_boussole.z_index = 30
    add_child(fleche_boussole)

    eclaireur_pnj = Polygon2D.new()
    eclaireur_pnj.z_index = 9
    eclaireur_pnj.visible = false
    var corp_ecl = Polygon2D.new()
    corp_ecl.polygon = PoolVector2Array([Vector2(-44,-20), Vector2(44,-20), Vector2(44,20), Vector2(-44,20)])
    corp_ecl.color = Color(0.18, 0.78, 0.36)
    eclaireur_pnj.add_child(corp_ecl)
    add_child(eclaireur_pnj)

    generer_nouvelle_mission(pos_depart)
    for i in range(24):
        var v = Polygon2D.new()
        var idx_dep = randi() % reseau_routes.size() if reseau_routes.size() > 0 else 0
        var p_dep = reseau_routes[idx_dep] if reseau_routes.size() > 0 else pos_depart + Vector2(i * 180, -220)
        v.position = p_dep; v.z_index = 5
        var car = Polygon2D.new()
        car.polygon = PoolVector2Array([Vector2(-38,-18), Vector2(38,-18), Vector2(38,18), Vector2(-38,18)])
        car.color = [Color(0.92,0.92,0.95), Color(0.2,0.45,0.75), Color(0.75,0.2,0.2), Color(0.22,0.24,0.26)][i % 4]
        v.add_child(car); v.set_meta("idx", idx_dep); add_child(v); trafic_autos.append(v)

func _choisir_poi_proche(ref_pos : Vector2, cat_voulue : String) -> Dictionary:
    var candidats := []
    for po in pois_reels:
        var apo := Array(po); var pp : Vector2 = apo.pop_front()
        var cat : String = apo.pop_front(); var nom_p : String = apo.pop_front()
        if cat == cat_voulue and nom_p != "" and nom_p != cat.capitalize():
            var d := pp.distance_to(ref_pos)
            if d > 1500.0 and d < 180000.0: candidats.append({"pos": pp, "nom": nom_p})
    return candidats[(mission_num * 13) % candidats.size()] if candidats.size() > 0 else {}

func generer_nouvelle_mission(pos_actuelle : Vector2 = Vector2.ZERO):
    var scenarios := [
        {"type": "tribu", "pnj": "Coutumier Téin", "nom": "Tribu de Néâria (Houaïlou)", "lat": -21.2654, "lon": 165.6106},
        {"type": "ravitaillement", "cat_poi": "magasin", "pnj": "Tante Marie", "nom": "Magasin du Village (Houaïlou)", "lat": -21.2810, "lon": 165.6290},
        {"type": "secours", "cat_poi": "hopital", "pnj": "Infirmière Loïc", "nom": "Dispensaire de Houaïlou", "lat": -21.2795, "lon": 165.6310},
        {"type": "convoyage", "cat_poi": "station", "pnj": "Tonton Manu (Éclaireur)", "nom": "Station & Route de Ponérihouen", "lat": -21.0740, "lon": 165.3980},
        {"type": "gendarmerie", "cat_poi": "police", "pnj": "Adjudant Kévin", "nom": "Brigade de Gendarmerie", "lat": -21.2780, "lon": 165.6330},
        {"type": "mer_ilot", "pnj": "Pêcheur Waïma", "nom": "Îlot Ain / Passe de Houaïlou (En Mer)", "lat": -21.2450, "lon": 165.6850},
        {"type": "mer_iles", "pnj": "Grand Chef de Wé (Lifou)", "nom": "Baie de Chépénéhé / Wé (Lifou)", "lat": -20.9160, "lon": 167.2630},
        {"type": "defense", "pnj": "Gardien du Réservoir", "nom": "Barrage & Captage d'Eau", "lat": -21.3100, "lon": 165.5950}
    ]
    var sc : Dictionary = scenarios[(mission_num - 1) % scenarios.size()]
    mission_type = sc["type"]; mission_pnj_nom = sc["pnj"]; mission_action_faite = false
    var p_main = get_parent()
    mission_bois_depart = p_main.bois if p_main != null else 0
    eclaireur_actif = (mission_type == "convoyage")
    var lieu_trouve := _choisir_poi_proche(pos_actuelle, sc["cat_poi"]) if (sc.has("cat_poi") and pos_actuelle != Vector2.ZERO) else {}
    mission_cible = lieu_trouve["pos"] if lieu_trouve.size() > 0 else gps_vers_jeu(sc["lat"], sc["lon"])
    mission_lieu_nom = lieu_trouve["nom"] if lieu_trouve.size() > 0 else sc["nom"]
    balise_sol.position = mission_cible
    mission_chrono = 25.0 if mission_type == "defense" else 0.0
    mission_titre = "Mission #" + str(mission_num) + " [" + mission_lieu_nom + "] -> " + mission_pnj_nom + " [Y]"
    if eclaireur_pnj != null:
        eclaireur_pnj.visible = eclaireur_actif
        if eclaireur_actif: eclaireur_pnj.position = pos_actuelle + Vector2(95, 0)
    if p_main != null and p_main.pop != null and mission_type == "gendarmerie":
        for _k in range(3): p_main.pop.spawn_ennemi(mission_cible + Vector2(rand_range(-160, 160), rand_range(-160, 160)), 1)

func _verifier_objectif_accompli(pos_joueur : Vector2) -> String:
    var p_main = get_parent()
    if mission_type == "tribu":
        var recolte : int = (p_main.bois - mission_bois_depart) if p_main != null else 15
        if recolte < 15: return "🪓 " + mission_pnj_nom + " : « Récolte encore " + str(15 - recolte) + " bois pour le faré ! »"
    elif mission_type == "ravitaillement" and not mission_action_faite:
        return "🏪 " + mission_pnj_nom + " : « Récupère d'abord les vivres au magasin avec [E] ! »"
    elif mission_type == "secours" and not mission_action_faite:
        return "🏥 " + mission_pnj_nom + " : « Prépare d'abord la trousse au dispensaire avec [E] ! »"
    elif mission_type == "convoyage" and eclaireur_pnj != null and eclaireur_pnj.position.distance_to(mission_cible) > 160.0:
        return "🚙 " + mission_pnj_nom + " : « Escorte mon 4x4 vert jusqu'à l'arrivée ! »"
    elif mission_type == "gendarmerie" and p_main != null and p_main.pop != null:
        var proches := 0
        for en in p_main.pop.ennemis:
            if en.position.distance_to(mission_cible) < 550.0: proches += 1
        if proches > 0: return "🚓 " + mission_pnj_nom + " : « Neutralise d'abord les " + str(proches) + " pilleurs [ESPACE] ! »"
    elif (mission_type == "mer_ilot" or mission_type == "mer_iles") and p_main != null and p_main.joueur != null and not p_main.joueur.en_vehicule and not mission_action_faite:
        return "🚤 " + mission_pnj_nom + " : « Arrive par la mer en bateau (ou [E] au quai) ! »"
    elif mission_type == "defense" and mission_chrono > 0.0:
        return "🛡️ Tiens encore la position (" + str(int(mission_chrono)) + "s) !"
    return ""

func valider_dialogue_pnj(pos_joueur : Vector2, hud : CanvasLayer) -> int:
    if pos_joueur.distance_to(mission_cible) > 220.0:
        hud.msg_label.text = "🧭 " + mission_pnj_nom + " t'attend à " + mission_lieu_nom + " (~" + str(int(pos_joueur.distance_to(mission_cible) / 16.5)) + " m) !"
        return 0
    var blocage := _verifier_objectif_accompli(pos_joueur)
    if blocage != "":
        hud.msg_label.text = blocage; return 0
    var gain := 110 + (mission_num * 15)
    var ancien := mission_pnj_nom
    mission_num += 1
    generer_nouvelle_mission(pos_joueur)
    hud.msg_label.text = "🏆 " + ancien + " : « Travail accompli, merci frère ! » (+" + str(gain) + " ress. & +250 XP) | " + mission_titre
    return gain

func maj_trafic_et_mission(delta : float, pos_joueur : Vector2, hud : CanvasLayer) -> int:
    fleche_boussole.position = pos_joueur; fleche_boussole.rotation = (mission_cible - pos_joueur).angle()
    if eclaireur_actif and eclaireur_pnj != null and eclaireur_pnj.position.distance_to(mission_cible) > 110.0:
        var d_j := eclaireur_pnj.position.distance_to(pos_joueur)
        var vit := 310.0 if d_j < 450.0 else (110.0 if d_j < 850.0 else 0.0)
        var dir_e := (mission_cible - eclaireur_pnj.position).normalized()
        eclaireur_pnj.rotation = dir_e.angle(); eclaireur_pnj.position += dir_e * vit * delta
    var total_pts = reseau_routes.size()
    if total_pts > 1:
        for v in trafic_autos:
            var idx = (v.get_meta("idx") + 1) % total_pts; var cible = reseau_routes[idx]
            if v.position.distance_to(pos_joueur) > 1800.0 or v.position.distance_to(cible) > 800.0:
                var r_idx = randi() % total_pts
                if reseau_routes[r_idx].distance_to(pos_joueur) < 1500.0:
                    v.position = reseau_routes[r_idx]; v.set_meta("idx", (r_idx + 1) % total_pts)
                continue
            if v.position.distance_to(cible) < 25.0: v.set_meta("idx", idx)
            var dir = (cible - v.position).normalized(); v.rotation = dir.angle(); v.position += dir * 240.0 * delta
    if pos_joueur.distance_to(mission_cible) < 185.0:
        if mission_type == "defense" and mission_chrono > 0.0:
            mission_chrono -= delta; hud.msg_label.text = "🛡️ DÉFENSE (" + str(int(mission_chrono)) + "s) — Protège " + mission_lieu_nom + " !"; return 0
        var blocage := _verifier_objectif_accompli(pos_joueur)
        hud.msg_label.text = blocage if blocage != "" else ("✅ Objectif accompli à " + mission_lieu_nom + " ! Parle à " + mission_pnj_nom + " [Y] !")
    return 0

func maj_radar(hud : CanvasLayer, pos_j : Vector2, allies : Array, vehicules : Array, cotes : Array = []):
    for p in points_radar: p.queue_free()
    points_radar.clear()
    var centre = Vector2(917, 182); var ech = 0.035
    var step_c = max(1, int(cotes.size() / 240)); var idx_c = 0
    while idx_c < cotes.size():
        ajouter_blip(hud, centre + (cotes[idx_c] - pos_j) * ech, Color(0.15, 0.78, 0.90, 0.85), 2); idx_c += step_c
    var step_r = max(1, int(reseau_routes.size() / 160)); var idx_r = 0
    while idx_r < reseau_routes.size():
        ajouter_blip(hud, centre + (reseau_routes[idx_r] - pos_j) * ech, Color(0.15, 0.55, 0.35, 0.7), 2); idx_r += step_r
    ajouter_blip(hud, centre + (mission_cible - pos_j) * ech, Color(1.0, 0.9, 0.1), 6)
    if eclaireur_actif and eclaireur_pnj != null: ajouter_blip(hud, centre + (eclaireur_pnj.position - pos_j) * ech, Color(0.2, 1.0, 0.4), 5)
    for a in allies: ajouter_blip(hud, centre + (a.position - pos_j) * ech, Color(0.2, 1.0, 0.4), 4)
    for v in vehicules: ajouter_blip(hud, centre + (v.position - pos_j) * ech, Color(0.3, 0.7, 1.0), 4)

func ajouter_blip(hud : CanvasLayer, pos : Vector2, coul : Color, taille : int):
    if pos.x < 838 or pos.x > 996 or pos.y < 103 or pos.y > 261: return
    var b = ColorRect.new(); b.color = coul; b.rect_position = pos; b.rect_size = Vector2(taille, taille)
    hud.add_child(b); points_radar.append(b)
