extends Node2D

const ApercuScript = preload("res://monde/ApercuConstruction.gd")
var LumieresScript = preload("res://scripts/LumieresNuit.gd")

const CarteScript = preload("res://scripts/CarteNC.gd")
const JoueurScript = preload("res://scripts/Joueur.gd")
const ConstrScript = preload("res://scripts/Construction.gd")
const HudScript = preload("res://scripts/InterfaceHUD.gd")
const ArmesScript = preload("res://scripts/Armes.gd")
const VehiculesScript = preload("res://scripts/Vehicules.gd")
const BatimentsScript = preload("res://scripts/Batiments.gd")
const PopScript = preload("res://scripts/Population.gd")
const MondeScript = preload("res://scripts/MondeVivant.gd")
const AudioScript = preload("res://scripts/Audio.gd")
const EcoScript = preload("res://scripts/EconomieQG.gd")
const PnjScript = preload("res://scripts/PNJDialogues.gd")
const ChunksScript = preload("res://scripts/ChunksNC.gd")

var carte : Node2D
var joueur : KinematicBody2D
var constr : Node2D
var hud : CanvasLayer
var armes : Node2D
var veh : Node2D
var bat : Node2D
var pop : Node2D
var monde : Node2D
var audio : Node
var eco : Node2D
var pnj : Node2D
var chunks : Node2D
var nuit_overlay : CanvasModulate
var lumieres : Node2D

var bois = 140
var metal = 60
var bidons = 2
var vivres = 5
var vague = 1
var niveau := 1
var xp := 0.0
var xp_max := 500.0
var armure := 35.0
var armure_max := 100.0
var tenue_nom := "Tenue Tribu"
var derniere_pos_xp := Vector2.ZERO
var dist_cumul_xp := 0.0
var est_nuit = false
var shake_timer := 0.0
var outil = 1
var temps_cycle = 0.0
var spawn_timer = 0.0
var caisses = []
var projectiles = []

func _ready():
    randomize()
    carte = CarteScript.new(); add_child(carte); carte.construire_carte("res://carte_noumea.json")
    constr = ConstrScript.new(); add_child(constr)
    armes = ArmesScript.new(); add_child(armes)
    veh = VehiculesScript.new(); veh.z_index = 8; add_child(veh); veh.generer_flotte_et_stations()
    bat = BatimentsScript.new(); add_child(bat)
    pop = PopScript.new(); pop.z_index = 9; add_child(pop); pop.peupler()
    monde = MondeScript.new(); add_child(monde); monde.initialiser_trafic(carte.points_routes, carte.lieux_nommes, carte.tous_pois)
    audio = AudioScript.new(); add_child(audio)
    eco = EcoScript.new(); add_child(eco)
    pnj = PnjScript.new(); add_child(pnj)
    chunks = ChunksScript.new(); add_child(chunks)
    joueur = JoueurScript.new(); joueur.z_index = 10; add_child(joueur)
    joueur.position = monde.gps_vers_jeu(-21.2652, 165.6159)
    carte.peupler_zone_depart(joueur.position)
    for ic in range(10):
        var c_box = ColorRect.new()
        c_box.rect_size = Vector2(28, 22); c_box.color = Color(0.76, 0.52, 0.18)
        c_box.rect_position = joueur.position + Vector2(cos(ic * 0.62) * (160 + ic * 35), sin(ic * 0.62) * (160 + ic * 35))
        c_box.set_meta("ouvert", false); add_child(c_box); caisses.append(c_box)
    pnj.creer_pnj_mission(monde.mission_cible)
    if veh != null and veh.vehicules.size() > 0:
        for iv in range(min(3, veh.vehicules.size())):
            veh.vehicules[iv].position = joueur.position + Vector2(85.0 * (iv + 1), 40.0)
    nuit_overlay = CanvasModulate.new(); add_child(nuit_overlay)
    lumieres = LumieresScript.new(); add_child(lumieres)
    hud = HudScript.new(); add_child(hud)
    hud.btn_aide.connect("pressed", self, "_toggle_aide")
    hud.btn_carte.connect("pressed", self, "_toggle_carte")
    hud.btn_zoom_in.connect("pressed", self, "_zoom_plus")
    hud.btn_zoom_out.connect("pressed", self, "_zoom_moins")
    generer_caisses(120)
    pnj.creer_pnj_mission(monde.mission_cible)
    pnj.spawner_civils_a_secourir(monde.mission_cible, 3)
    hud.msg_label.text = "🌴 " + monde.mission_titre

func _toggle_aide():
    hud.aide_panel.visible = not hud.aide_panel.visible
    hud.carte_panel.visible = false

func _zoom_plus(): joueur.cam.zoom *= 0.72

func _zoom_moins(): joueur.cam.zoom *= 1.40

func _toggle_carte():
    hud.carte_panel.visible = not hud.carte_panel.visible
    hud.aide_panel.visible = false

func generer_caisses(nb : int):
    for i in range(nb):
        var c = Polygon2D.new()
        c.position = Vector2(75, 55) if i == 0 else Vector2(rand_range(-2800, 3200), rand_range(-4500, 2800))
        var vis = Polygon2D.new()
        vis.polygon = PoolVector2Array([Vector2(-15,-15), Vector2(15,-15), Vector2(15,15), Vector2(-15,15)])
        var t = i % 5
        vis.color = [Color(0.88,0.62,0.20), Color(0.55,0.68,0.78), Color(0.20,0.88,0.35), Color(0.95,0.88,0.15), Color(0.90,0.30,0.25)][t]
        c.add_child(vis); c.set_meta("type", t); c.z_index = 6; add_child(c); caisses.append(c)

func _physics_process(delta):
    chunks.verifier_chunks(joueur.position)
    if armes.mode_lunette and armes.arme_idx == 4:
        joueur.cam.offset = (get_global_mouse_position() - joueur.position) * 0.45
    elif shake_timer > 0.0:
        shake_timer -= delta
        joueur.cam.offset = Vector2(rand_range(-14.0, 14.0), rand_range(-14.0, 14.0))
    else:
        joueur.cam.offset = Vector2.ZERO
    if joueur.pv <= 0:
        hud.msg_label.text = "💀 TU ES TOMBÉ ! Appuie sur [R] pour revivre ou [F9] pour charger."
        return
    temps_cycle += delta
    if temps_cycle >= 180.0:
        temps_cycle = 0.0; est_nuit = not est_nuit; joueur.lampe.visible = est_nuit
        nuit_overlay.color = Color(0.14, 0.18, 0.30) if est_nuit else Color(1, 1, 1)
        if not est_nuit: vague += 1
    if joueur.en_vehicule and joueur.vehicule_ref != null:
        var ess = joueur.vehicule_ref.get_meta("essence")
        if ess <= 0.0:
            joueur.vehicule_ref.set_meta("vit", 0.0)
            hud.msg_label.text = "⛽ PANNE SÈCHE ! Appuie sur [T] avec un bidon ou à la station !"
        else:
            joueur.vehicule_ref.set_meta("vit", joueur.vehicule_ref.get_meta("vit_max"))
            if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):
                joueur.vehicule_ref.set_meta("essence", max(0.0, ess - 0.25 * delta))
    for fc in lumieres.feux_camp:
        if joueur.position.distance_to(fc["pos"]) < 150.0:
            joueur.energie = min(joueur.energie_max, joueur.energie + 18.0 * delta)
    if armes.cooldown > 0: armes.cooldown -= delta
    if Input.is_key_pressed(KEY_SPACE) and armes.cooldown <= 0 and not hud.aide_panel.visible and not hud.carte_panel.visible:
        var err = armes.tirer(joueur.position, (get_global_mouse_position() - joueur.position).normalized(), self, projectiles)
        if err == "": audio.p_tir.play()
        else: hud.msg_label.text = err
    if est_nuit:
        spawn_timer -= delta
        if spawn_timer <= 0:
            spawn_timer = max(1.2, 4.0 - vague * 0.3)
            pop.spawn_ennemi(joueur.position, vague)
    var gain = monde.maj_trafic_et_mission(delta, joueur.position, hud)
    if monde.mission_type == "defense" and joueur.position.distance_to(monde.mission_cible) < 220.0 and randf() < 0.025:
        pop.spawn_ennemi(joueur.position, vague)
    for civ in pnj.civils_mission:
        if joueur.position.distance_to(civ.position) < 95.0:
            civ.set_meta("sauve", true)
        if civ.get_meta("sauve") and civ.position.distance_to(joueur.position) > 85.0:
            civ.move_and_slide((joueur.position - civ.position).normalized() * 320.0)
    if gain > 0:
        bois += gain
        metal += gain / 2
        eco.argent += 1500
        pnj.creer_pnj_mission(monde.mission_cible)
        pnj.spawner_civils_a_secourir(monde.mission_cible, 3)
        audio.p_ok.play()
    monde.maj_radar(hud, joueur.position, pop.allies, veh.vehicules, carte.points_cotes)
    var msg_b = eco.maj_bombes(delta, pop.ennemis, joueur)
    if msg_b != "":
        hud.msg_label.text = msg_b; audio.p_boom.play(); shake_timer = 0.45; gagner_xp(40.0, "Explosif")
    gerer_combat(delta)
    var nb_al = 0
    for a in pop.allies:
        var cd_a = a.get_meta("cd") - delta; a.set_meta("cd", cd_a)
        if a.get_meta("recrute"):
            nb_al += 1
            if joueur.en_vehicule and joueur.vehicule_ref != null and nb_al < joueur.vehicule_ref.get_meta("places"):
                a.visible = false; a.position = joueur.position
            else:
                a.visible = true
                if a.position.distance_to(joueur.position) > 110.0:
                    a.look_at(joueur.position); a.move_and_slide((joueur.position - a.position).normalized() * 340.0)
            for en_d in pop.ennemis:
                if a.visible and a.position.distance_to(en_d.position) < 420.0 and cd_a <= 0:
                    a.set_meta("cd", 0.65); a.look_at(en_d.position)
                    armes.creer_balle(a.position, (en_d.position - a.position).normalized(), 1.2, 30, Color(0.3, 1.0, 0.5), self, projectiles)
                    break
    var ess_act = joueur.vehicule_ref.get_meta("essence") if (joueur.en_vehicule and joueur.vehicule_ref != null) else 100.0
    var nom_v = joueur.vehicule_ref.get_meta("nom") if (joueur.en_vehicule and joueur.vehicule_ref != null) else ""
    if derniere_pos_xp == Vector2.ZERO: derniere_pos_xp = joueur.position
    dist_cumul_xp += joueur.position.distance_to(derniere_pos_xp)
    derniere_pos_xp = joueur.position
    if dist_cumul_xp >= 8250.0:
        dist_cumul_xp = 0.0
        gagner_xp(15.0, "Exploration 500 m")
    var pv_veh_txt := ""
    if joueur.en_vehicule and joueur.vehicule_ref != null:
        if not joueur.vehicule_ref.has_meta("pv_veh"): joueur.vehicule_ref.set_meta("pv_veh", 100.0)
        pv_veh_txt = " | 🚙 Vie Véhicule: " + str(int(joueur.vehicule_ref.get_meta("pv_veh"))) + "%"
    if hud.xp_bar != null:
        hud.xp_bar.max_value = xp_max
        hud.xp_bar.value = xp
        hud.lbl_stats_perso.text = "Niv." + str(niveau) + " (" + str(int(xp)) + "/" + str(int(xp_max)) + " XP) | 🛡️ Armure [" + tenue_nom + "]: " + str(int(armure)) + "%" + pv_veh_txt
    hud.maj_texte(joueur.pv, joueur.energie, ess_act, est_nuit, vague, bois, metal, bidons, vivres, armes.noms[armes.arme_idx], armes.chargeurs[armes.arme_idx], armes.reserve, nb_al, nom_v)

func gagner_xp(pts : float, raison : String = ""):
    xp += pts
    while xp >= xp_max:
        xp -= xp_max
        niveau += 1
        xp_max = round(xp_max * 1.25)
        joueur.pv_max += 10
        joueur.pv = joueur.pv_max
        armure = min(armure_max, armure + 20.0)
        hud.msg_label.text = "⭐ NIVEAU " + str(niveau) + " ATTEINT ! PV Max +10 & Armure +20 (" + raison + ")"

func gerer_combat(delta):
    for i in range(projectiles.size() - 1, -1, -1):
        var p = projectiles[i]; p.position += p.get_meta("dir") * 680.0 * delta; var v = p.get_meta("vie") - delta; p.set_meta("vie", v); var hit = false
        var msg_e = veh.verifier_explosion_pompe(p.position, pop.ennemis, joueur)
        if msg_e != "": hud.msg_label.text = msg_e; audio.p_boom.play(); hit = true
        if p.color == Color(1.0, 0.2, 0.2) and p.position.distance_to(joueur.position) < 26.0:
            hit = true
            if joueur.en_vehicule and joueur.vehicule_ref != null:
                if not joueur.vehicule_ref.has_meta("pv_veh"): joueur.vehicule_ref.set_meta("pv_veh", 100.0)
                var pv_v = max(0.0, joueur.vehicule_ref.get_meta("pv_veh") - 12.0)
                joueur.vehicule_ref.set_meta("pv_veh", pv_v)
                var e_v = joueur.vehicule_ref.get_meta("essence") - 5.0
                joueur.vehicule_ref.set_meta("essence", max(0.0, e_v))
                hud.msg_label.text = "💥 Véhicule touché ! Vie véhicule : " + str(int(pv_v)) + "%"
                if pv_v <= 0.0:
                    joueur.en_vehicule = false; joueur.vehicule_ref = null
                    hud.msg_label.text = "🔥 Véhicule hors service ! Sors à pied ou répare avec [T] !"
            else:
                var deg : float = p.get_meta("degats")
                if armure > 0.0:
                    var abs_arm := min(armure, deg * 0.7)
                    armure -= abs_arm
                    deg -= abs_arm
                joueur.pv = max(0.0, joueur.pv - deg)
        for j in range(pop.ennemis.size() - 1, -1, -1):
            var en = pop.ennemis[j]
            if p.position.distance_to(en.position) < 42.0:
                var hp = en.get_meta("hp") - p.get_meta("degats"); en.set_meta("hp", hp); hit = true
                if hp <= 0:
                    en.queue_free()
                    pop.ennemis.remove(j)
                    bois += 6
                    metal += 3
                    armes.reserve += 5; gagner_xp(25.0, "Cible neutralisée")
                break
        if v <= 0 or hit:
            p.queue_free()
            projectiles.remove(i)
    for k in range(pop.ennemis.size() - 1, -1, -1):
        var en2 = pop.ennemis[k]; var cd = en2.get_meta("cd") - delta; en2.set_meta("cd", cd); en2.look_at(joueur.position)
        en2.move_and_slide((joueur.position - en2.position).normalized() * (165.0 + vague * 10.0))
        if en2.get_meta("arme") and en2.position.distance_to(joueur.position) < 420.0 and cd <= 0:
            en2.set_meta("cd", 1.8)
            armes.creer_balle(en2.position, (joueur.position - en2.position).normalized(), 1.0, 10, Color(1.0, 0.2, 0.2), self, projectiles)
        var veh_roule := Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT)
        if joueur.en_vehicule and veh_roule and en2.position.distance_to(joueur.position) < 58.0:
            en2.queue_free(); pop.ennemis.remove(k); bois += 4; gagner_xp(20.0, "Choc véhicule")
            continue
        if joueur.en_vehicule and not veh_roule and en2.position.distance_to(joueur.position) < 52.0 and cd <= 0 and joueur.vehicule_ref != null:
            en2.set_meta("cd", 1.1)
            if not joueur.vehicule_ref.has_meta("pv_veh"): joueur.vehicule_ref.set_meta("pv_veh", 100.0)
            var pv_v2 = max(0.0, joueur.vehicule_ref.get_meta("pv_veh") - 8.0)
            joueur.vehicule_ref.set_meta("pv_veh", pv_v2)
            hud.msg_label.text = "⚠️ Un assaillant frappe ton véhicule à l'arrêt ! Vie véhicule : " + str(int(pv_v2)) + "%"
            continue
        if not joueur.en_vehicule and not bat.sur_toit and en2.position.distance_to(joueur.position) < 34.0 and cd <= 0:
            en2.set_meta("cd", 1.0)
            joueur.pv = max(0.0, joueur.pv - 12.0)

func pres_dun_batiment() -> bool:
    for bp in carte.centres_batiments:
        if joueur.position.distance_to(bp) < 350.0:
            return true
    return false

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == BUTTON_LEFT and not hud.carte_panel.visible and not hud.aide_panel.visible:
            var coupe = carte.recolter_arbre_proche(joueur.position, 115.0) if (not joueur.en_vehicule and arme_ou_hache_proche()) else 0
            if coupe > 0:
                bois += coupe; gagner_xp(12.0, "Récolte de bois"); audio.p_ok.play()
                hud.msg_label.text = "🪓 Arbre coupé ! +" + str(coupe) + " bois & +12 XP (Total : " + str(bois) + ")"
            elif armes.cooldown <= 0:
                var err = armes.tirer(joueur.position, (get_global_mouse_position() - joueur.position).normalized(), self, projectiles)
                if err == "": audio.p_tir.play()
                else: hud.msg_label.text = err
        elif event.button_index == BUTTON_RIGHT and not hud.carte_panel.visible and not hud.aide_panel.visible and not joueur.en_vehicule:
            if outil == 1 and bois >= 10:
                bois -= 10; constr.poser_structure(get_global_mouse_position(), joueur.position, 1); gagner_xp(15.0, "Palissade")
                hud.msg_label.text = "🪵 Palissade construite ! (-10 bois)"
            elif outil == 2 and bois >= 20 and metal >= 10:
                bois -= 20; metal -= 10; constr.poser_structure(get_global_mouse_position(), joueur.position, 2); gagner_xp(30.0, "Cabane / Faré")
                hud.msg_label.text = "🛖 Cabane / Faré refuge construit ! (-20 bois, -10 métal)"
            elif outil == 3 and bois >= 15 and metal >= 15:
                bois -= 15; metal -= 15; constr.poser_structure(get_global_mouse_position(), joueur.position, 3); gagner_xp(25.0, "Tourelle")
                hud.msg_label.text = "🔫 Tourelle installée ! (-15 bois, -15 métal)"
            else:
                hud.msg_label.text = "❌ Ressources insuffisantes pour construire (Outil " + str(outil) + ") !"
        elif event.button_index == BUTTON_WHEEL_UP: joueur.cam.zoom *= 0.75
        elif event.button_index == BUTTON_WHEEL_DOWN: joueur.cam.zoom *= 1.35
    elif event is InputEventKey and event.pressed:
        match event.scancode:
            KEY_ESCAPE: _toggle_aide()
            KEY_TAB: hud.msg_label.text = armes.changer_arme()
            KEY_V:
                if not joueur.en_vehicule: hud.msg_label.text = bat.basculer(joueur)
            KEY_C:
                if vivres > 0:
                    vivres -= 1; joueur.pv = min(joueur.pv_max, joueur.pv + 25.0); joueur.energie = 100.0; audio.p_ok.play()
                    hud.msg_label.text = "🥫 Vivres consommés (+25 PV & Énergie 100%) !"
            KEY_E:
                var fait_e := false
                for i in range(caisses.size() - 1, -1, -1):
                    if joueur.position.distance_to(caisses[i].position) < 110.0:
                        var t = caisses[i].get_meta("type") if caisses[i].has_meta("type") else (i % 5)
                        caisses[i].queue_free(); caisses.remove(i); fait_e = true
                        if t == 0: bois += 25
                        elif t == 1: metal += 20
                        elif t == 2: joueur.pv = min(joueur.pv_max, joueur.pv + 30.0)
                        elif t == 3: armes.reserve += 35
                        else: bidons += 1; vivres += 2
                        gagner_xp(20.0, "Coffre fouillé"); audio.p_ok.play(); hud.msg_label.text = "📦 Coffre fouillé !"; break
                if not fait_e:
                    for po in carte.tous_pois:
                        var apo := Array(po); var pp : Vector2 = apo.pop_front()
                        if pp.distance_to(joueur.position) < 170.0:
                            var cat : String = apo.pop_front(); var nom_p : String = apo.pop_front(); fait_e = true; monde.mission_action_faite = true; gagner_xp(40.0, nom_p)
                            if cat == "station":
                                bidons += 1
                                if joueur.en_vehicule and joueur.vehicule_ref != null:
                                    joueur.vehicule_ref.set_meta("essence", 100.0); joueur.vehicule_ref.set_meta("pv_veh", 100.0)
                                hud.msg_label.text = "⛽ [" + nom_p + "] : Plein + Réparation 100% + 1 bidon !"
                            elif cat == "hopital":
                                joueur.pv = joueur.pv_max; joueur.energie = joueur.energie_max; vivres += 1
                                hud.msg_label.text = "🏥 [" + nom_p + "] : Soins complets (100%) + 1 vivre !"
                            elif cat == "police":
                                armes.reserve += 25; tenue_nom = "Gilet Tactique"; armure = 100.0
                                hud.msg_label.text = "🚓 [" + nom_p + "] : +25 balles + Gilet Tactique (Armure 100%) !"
                            else:
                                vivres += 3; bois += 15; metal += 10
                                hud.msg_label.text = "🏪 [" + nom_p + "] : Ravitaillement (+3 vivres, +15 bois, +10 métal) !"
                            audio.p_ok.play(); break
                if not fait_e: hud.msg_label.text = "ℹ️ Approche-toi d'un coffre, magasin, station, dispensaire ou gendarmerie [E]."
            KEY_Y:
                var gain_m = monde.valider_dialogue_pnj(joueur.position, hud)
                if gain_m > 0:
                    bois += gain_m; metal += gain_m / 2; vivres += 2; eco.argent += 2000; gagner_xp(250.0, "Mission accomplie")
                    pnj.creer_pnj_mission(monde.mission_cible); pnj.spawner_civils_a_secourir(monde.mission_cible, 3); audio.p_ok.play()
            KEY_B:
                if bois >= 3:
                    bois -= 3; lumieres.allumer_feu(joueur.position + Vector2(36, 0).rotated(joueur.corps_visuel.rotation)); audio.p_ok.play()
                    hud.msg_label.text = "🔥 Feu de camp allumé au briquet ! (-3 bois, éclaire la nuit & recharge l'énergie)"
                else: hud.msg_label.text = "🪵 Il faut 3 bois pour allumer un feu de camp au briquet [B] !"
            KEY_U:
                joueur.lampe.visible = not joueur.lampe.visible
                hud.msg_label.text = "🔦 Lampe torche : " + ("ALLUMÉE" if joueur.lampe.visible else "ÉTEINTE")
            KEY_T:
                var rp = veh.faire_le_plein(joueur.position, joueur.vehicule_ref, bidons); bidons = rp["bidons"]; hud.msg_label.text = rp["msg"]
                if joueur.en_vehicule and joueur.vehicule_ref != null and metal >= 5:
                    metal -= 5; joueur.vehicule_ref.set_meta("pv_veh", 100.0); hud.msg_label.text += " | 🔧 Carrosserie réparée (100%) !"
                if rp["ok"]: audio.p_ok.play()
            KEY_F:
                if joueur.en_vehicule:
                    joueur.en_vehicule = false; joueur.corps_visuel.visible = true; joueur.position += Vector2(0, 48); joueur.vehicule_ref = null
                else:
                    for v in veh.vehicules:
                        if joueur.position.distance_to(v.position) < 120.0:
                            joueur.en_vehicule = true; joueur.vehicule_ref = v; joueur.corps_visuel.visible = false; joueur.position = v.position
                            hud.msg_label.text = "🚙 Véhicule : " + v.get_meta("nom"); break
            KEY_G:
                for a in pop.allies:
                    if not a.get_meta("recrute") and joueur.position.distance_to(a.position) < 260.0:
                        a.set_meta("recrute", true); audio.p_ok.play(); gagner_xp(30.0, "Cousin recruté")
                        hud.msg_label.text = "🤝 Cousin / Allié recruté dans ton équipe !"; break
            KEY_P:
                hud.tel_panel.visible = not hud.tel_panel.visible
            KEY_X: hud.msg_label.text = eco.poser_explosif(joueur.position)
            KEY_K:
                if not joueur.en_vehicule: hud.msg_label.text = eco.poser_coffre_qg(joueur.position)
            KEY_F1:
                joueur.position = Vector2(0, 0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Nouméa (Anse Vata)"
            KEY_F2:
                joueur.position = Vector2(-2404668.3, -2049300.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Koné / Pouembout"
            KEY_F3:
                joueur.position = Vector2(-1440327.9, -1209450.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Bourail"
            KEY_F4:
                joueur.position = Vector2(1593749.1, 599775.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚤 Voyage rapide : Île des Pins (Kuto)"
            KEY_F6:
                joueur.position = Vector2(1209509.1, -2284920.0); hud.carte_panel.visible = false; hud.msg_label.text = "🛩️ Voyage rapide : Lifou (Wé)"
            KEY_F7:
                joueur.position = monde.gps_vers_jeu(-21.2652, 165.6159); hud.carte_panel.visible = false; hud.msg_label.text = "🌴 Voyage rapide : Houaïlou (Tribu)"
            KEY_1:
                outil = 1; hud.msg_label.text = "🔨 Construction [Clic Droit] : 1 = Palissade (10 bois)"
            KEY_2:
                outil = 2; hud.msg_label.text = "🛖 Construction [Clic Droit] : 2 = Cabane / Faré (20 bois, 10 métal)"
            KEY_3:
                outil = 3; hud.msg_label.text = "🔫 Construction [Clic Droit] : 3 = Tourelle (15 bois, 15 métal)"

func arme_ou_hache_proche() -> bool:
    for en in pop.ennemis:
        if en.position.distance_to(joueur.position) < 450.0: return false
    return true
