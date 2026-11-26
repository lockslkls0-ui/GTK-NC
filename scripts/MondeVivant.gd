extends Node2D

var trafic_autos := []
var mission_titre := "Mission #1 [Anse Vata - Promenade Roger Laroque] : Parle au PNJ orange [Y] ou rallie la balise !"
var mission_type := "sauvetage"
var mission_cible := Vector2(320, 180)
var mission_chrono := 0.0
var mission_num := 1
var points_radar := []
var reseau_routes := []
var lieux_reels_carte := []
var balise_sol : Polygon2D
var fleche_boussole : Polygon2D

func gps_vers_jeu(lat : float, lon : float) -> Vector2:
    var lat0 := -22.3015
    var lon0 := 166.4410
    var echelle := 1650000.0
    return Vector2((lon - lon0) * echelle * cos(deg2rad(lat0)), -(lat - lat0) * echelle)

func initialiser_trafic(pts_routes : Array, lieux_carte : Array = []):
    lieux_reels_carte = lieux_carte
    reseau_routes = pts_routes
    mission_cible = gps_vers_jeu(-22.3025, 166.4425)
    balise_sol = Polygon2D.new()
    balise_sol.polygon = PoolVector2Array([Vector2(-55,-55), Vector2(55,-55), Vector2(55,55), Vector2(-55,55)])
    balise_sol.color = Color(1.0, 0.85, 0.1, 0.42)
    balise_sol.z_index = 3
    balise_sol.position = mission_cible
    add_child(balise_sol)

    fleche_boussole = Polygon2D.new()
    fleche_boussole.polygon = PoolVector2Array([Vector2(45,-8), Vector2(68,0), Vector2(45,8)])
    fleche_boussole.color = Color(1.0, 0.9, 0.1)
    fleche_boussole.z_index = 12
    add_child(fleche_boussole)

    for i in range(22):
        var v = Node2D.new()
        var idx_dep = randi() % reseau_routes.size() if reseau_routes.size() > 0 else 0
        var p_dep = reseau_routes[idx_dep] if reseau_routes.size() > 0 else Vector2(i * 150, -200)
        v.position = p_dep; v.z_index = 5
        var car = Polygon2D.new()
        car.polygon = PoolVector2Array([Vector2(-38,-18), Vector2(38,-18), Vector2(38,18), Vector2(-38,18)])
        car.color = [Color(0.92,0.92,0.95), Color(0.2,0.45,0.75), Color(0.75,0.2,0.2), Color(0.22,0.24,0.26)][i % 4]
        v.add_child(car); v.set_meta("idx", idx_dep); add_child(v); trafic_autos.append(v)

func generer_nouvelle_mission():
    var types = ["sauvetage", "defense", "station", "escorte"]
    var lieux_reels = [
        {"nom": "Baie des Citrons (Front de Mer)", "lat": -22.2958, "lon": 166.4368},
        {"nom": "Belvédère du Ouen Toro", "lat": -22.3075, "lon": 166.4535},
        {"nom": "Anse Vata (Hippodrome)", "lat": -22.3005, "lon": 166.4455},
        {"nom": "Baie de l'Orphelinat", "lat": -22.2885, "lon": 166.4385},
        {"nom": "Quartier Latin / Centre", "lat": -22.2765, "lon": 166.4420},
        {"nom": "Port Moselle", "lat": -22.2750, "lon": 166.4360}
    ]
    mission_type = types[mission_num % types.size()]
    var lieu = lieux_reels[mission_num % lieux_reels.size()]
    if lieux_reels_carte.size() > 0:
        lieu = lieux_reels_carte[(mission_num * 7) % lieux_reels_carte.size()]
        mission_cible = lieu["pos"]
    else:
        mission_cible = gps_vers_jeu(lieu["lat"], lieu["lon"])
    balise_sol.position = mission_cible
    if mission_type == "defense":
        mission_chrono = 25.0
        mission_titre = "Mission #" + str(mission_num) + " [Défense 25s] : Tiens " + lieu["nom"] + " contre la vague !"
    elif mission_type == "sauvetage":
        mission_titre = "Mission #" + str(mission_num) + " [Sauvetage] : Récupère les civils à " + lieu["nom"] + " !"
    else:
        mission_titre = "Mission #" + str(mission_num) + " [Sécurisation] : Rallie " + lieu["nom"] + " et parle au PNJ [Y] !"

func maj_trafic_et_mission(delta : float, pos_joueur : Vector2, hud : CanvasLayer) -> int:
    fleche_boussole.position = pos_joueur
    fleche_boussole.rotation = (mission_cible - pos_joueur).angle()

    var total_pts = reseau_routes.size()
    if total_pts > 1:
        for v in trafic_autos:
            var idx = (v.get_meta("idx") + 1) % total_pts
            var cible = reseau_routes[idx]
            if v.position.distance_to(pos_joueur) > 1800.0 or v.position.distance_to(cible) > 800.0:
                var r_idx = randi() % total_pts
                if reseau_routes[r_idx].distance_to(pos_joueur) < 1500.0:
                    v.position = reseau_routes[r_idx]
                    v.set_meta("idx", (r_idx + 1) % total_pts)
                continue
            if v.position.distance_to(cible) < 25.0: v.set_meta("idx", idx)
            var dir = (cible - v.position).normalized()
            v.rotation = dir.angle(); v.position += dir * 240.0 * delta

    if pos_joueur.distance_to(mission_cible) < 145.0:
        if mission_type == "defense" and mission_chrono > 0.0:
            mission_chrono -= delta
            hud.msg_label.text = "🛡️ DÉFENSE DE POSITION (" + str(int(mission_chrono)) + "s) — Repousse les assaillants !"
            return 0
        var gain = 70 + (mission_num * 10)
        mission_num += 1
        generer_nouvelle_mission()
        hud.msg_label.text = "🏆 MISSION RÉUSSIE ! +" + str(gain) + " Ressources & +1500 F ! Suivante : " + mission_titre
        return gain
    return 0

func maj_radar(hud : CanvasLayer, pos_j : Vector2, allies : Array, vehicules : Array, cotes : Array = []):
    for p in points_radar: p.queue_free()
    points_radar.clear()
    var centre = Vector2(917, 182)
    var ech = 0.035
    var step_c = max(1, int(cotes.size() / 240))
    var idx_c = 0
    while idx_c < cotes.size():
        ajouter_blip(hud, centre + (cotes[idx_c] - pos_j) * ech, Color(0.15, 0.78, 0.90, 0.85), 2)
        idx_c += step_c
    var step_r = max(1, int(reseau_routes.size() / 160))
    var idx_r = 0
    while idx_r < reseau_routes.size():
        ajouter_blip(hud, centre + (reseau_routes[idx_r] - pos_j) * ech, Color(0.15, 0.55, 0.35, 0.7), 2)
        idx_r += step_r
    ajouter_blip(hud, centre + (mission_cible - pos_j) * ech, Color(1.0, 0.9, 0.1), 6)
    for a in allies: ajouter_blip(hud, centre + (a.position - pos_j) * ech, Color(0.2, 1.0, 0.4), 4)
    for v in vehicules: ajouter_blip(hud, centre + (v.position - pos_j) * ech, Color(0.3, 0.7, 1.0), 4)

func ajouter_blip(hud : CanvasLayer, pos : Vector2, coul : Color, taille : int):
    if pos.x < 838 or pos.x > 996 or pos.y < 103 or pos.y > 261: return
    var b = ColorRect.new(); b.color = coul; b.rect_position = pos; b.rect_size = Vector2(taille, taille)
    hud.add_child(b); points_radar.append(b)
