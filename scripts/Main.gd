extends Node2D
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
var est_nuit = false
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
    veh = VehiculesScript.new(); add_child(veh); veh.generer_flotte_et_stations()
    bat = BatimentsScript.new(); add_child(bat)
    pop = PopScript.new(); add_child(pop); pop.peupler()
    monde = MondeScript.new(); add_child(monde); monde.initialiser_trafic(carte.points_routes, carte.lieux_nommes)
    audio = AudioScript.new(); add_child(audio)
    eco = EcoScript.new(); add_child(eco)
    pnj = PnjScript.new(); add_child(pnj)
    chunks = ChunksScript.new(); add_child(chunks)
    joueur = JoueurScript.new(); add_child(joueur)
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
        var c = Node2D.new()
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
        hud.msg_label.text = msg_b
        audio.p_boom.play()
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
    hud.maj_texte(joueur.pv, joueur.energie, ess_act, est_nuit, vague, bois, metal, bidons, vivres, armes.noms[armes.arme_idx], armes.chargeurs[armes.arme_idx], armes.reserve, nb_al, nom_v)

func gerer_combat(delta):
    for i in range(projectiles.size() - 1, -1, -1):
        var p = projectiles[i]; p.position += p.get_meta("dir") * 680.0 * delta; var v = p.get_meta("vie") - delta; p.set_meta("vie", v); var hit = false
        var msg_e = veh.verifier_explosion_pompe(p.position, pop.ennemis, joueur)
        if msg_e != "": hud.msg_label.text = msg_e; audio.p_boom.play(); hit = true
        if p.color == Color(1.0, 0.2, 0.2) and p.position.distance_to(joueur.position) < 26.0:
            hit = true
            if joueur.en_vehicule and joueur.vehicule_ref != null:
                var e_v = joueur.vehicule_ref.get_meta("essence") - 8.0
                joueur.vehicule_ref.set_meta("essence", max(0.0, e_v))
                hud.msg_label.text = "💥 Ton véhicule est touché (-8% réservoir) !"
            else:
                joueur.pv = max(0.0, joueur.pv - p.get_meta("degats"))
        for j in range(pop.ennemis.size() - 1, -1, -1):
            var en = pop.ennemis[j]
            if p.position.distance_to(en.position) < 26.0:
                var hp = en.get_meta("hp") - p.get_meta("degats"); en.set_meta("hp", hp); hit = true
                if hp <= 0:
                    en.queue_free()
                    pop.ennemis.remove(j)
                    bois += 6
                    metal += 3
                    armes.reserve += 5
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
        if joueur.en_vehicule and en2.position.distance_to(joueur.position) < 55.0:
            en2.queue_free()
            pop.ennemis.remove(k)
            bois += 4
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
        if event.button_index == BUTTON_LEFT and not hud.carte_panel.visible and not hud.aide_panel.visible and not joueur.en_vehicule:
            if outil == 1 and bois >= 10:
                bois -= 10
                constr.poser_structure(get_global_mouse_position(), joueur.position, 1)
            elif outil == 2 and bois >= 20 and metal >= 10:
                bois -= 20
                metal -= 10
                constr.poser_structure(get_global_mouse_position(), joueur.position, 2)
            elif outil == 3 and bois >= 15 and metal >= 15:
                bois -= 15
                metal -= 15
                constr.poser_structure(get_global_mouse_position(), joueur.position, 3)
        elif event.button_index == BUTTON_RIGHT and armes.cooldown <= 0 and not hud.carte_panel.visible and not hud.aide_panel.visible:
            var err = armes.tirer(joueur.position, (get_global_mouse_position() - joueur.position).normalized(), self, projectiles)
            if err == "": audio.p_tir.play()
            else: hud.msg_label.text = err
        elif event.button_index == BUTTON_WHEEL_UP: joueur.cam.zoom *= 0.75
        elif event.button_index == BUTTON_WHEEL_DOWN: joueur.cam.zoom *= 1.35
    elif event is InputEventKey and event.pressed:
        if event.scancode == KEY_H or event.scancode == KEY_ESCAPE: _toggle_aide()
        elif event.scancode == KEY_M: _toggle_carte()
        elif event.scancode == KEY_N: joueur.cam.zoom = Vector2(min(joueur.cam.zoom.x * 1.4, 65.0), min(joueur.cam.zoom.y * 1.4, 65.0))
        elif event.scancode == KEY_J: joueur.cam.zoom = Vector2(max(joueur.cam.zoom.x * 0.7, 0.30), max(joueur.cam.zoom.y * 0.7, 0.30))
        elif event.scancode == KEY_TAB: hud.msg_label.text = armes.changer_arme()
        elif event.scancode == KEY_V and not joueur.en_vehicule: hud.msg_label.text = bat.basculer(joueur)
        elif event.scancode == KEY_C and vivres > 0:
            vivres -= 1
            joueur.pv = min(100.0, joueur.pv + 25.0)
            joueur.energie = 100.0
            audio.p_ok.play()
            hud.msg_label.text = "🥫 Vivres consommés !"
        elif event.scancode == KEY_E:
            for i in range(caisses.size() - 1, -1, -1):
                if joueur.position.distance_to(caisses[i].position) < 95.0:
                    var t = caisses[i].get_meta("type"); caisses[i].queue_free(); caisses.remove(i)
                    if t == 0: bois += 25
                    elif t == 1: metal += 20
                    elif t == 2: joueur.pv = min(100.0, joueur.pv + 30.0)
                    elif t == 3: armes.reserve += 35
                    else:
                        bidons += 1
                        vivres += 2
                    audio.p_ok.play(); hud.msg_label.text = "📦 Caisse fouillée !"; break
        elif event.scancode == KEY_T:
            var rp = veh.faire_le_plein(joueur.position, joueur.vehicule_ref, bidons); bidons = rp["bidons"]; hud.msg_label.text = rp["msg"]
            if rp["ok"]: audio.p_ok.play()
        elif event.scancode == KEY_L and not joueur.en_vehicule:
            if bat.sur_toit or pres_dun_batiment(): hud.msg_label.text = bat.monter_echelle(joueur)
            else: hud.msg_label.text = "🪜 Approche-toi du mur d'un vrai bâtiment pour poser l'échelle [L] !"
        elif event.scancode == KEY_B:
            if armes.arme_idx == 4:
                armes.mode_lunette = not armes.mode_lunette
                hud.lunette_panel.visible = armes.mode_lunette
                joueur.cam.zoom = Vector2(0.42, 0.42) if armes.mode_lunette else Vector2(0.85, 0.85)
            else:
                hud.msg_label.text = "🔭 Équipe d'abord le Sniper Lunette avec [Tab] !"
        elif event.scancode == KEY_R:
            if joueur.pv <= 0:
                joueur.pv = 100.0
                joueur.energie = 100.0
                hud.msg_label.text = "❤️ Tu es revenu à la vie à Nouméa !"
            else:
                hud.msg_label.text = armes.recharger()
                audio.p_ok.play()
        elif event.scancode == KEY_F:
            if joueur.en_vehicule:
                joueur.en_vehicule = false
                joueur.corps_visuel.visible = true
                joueur.position += Vector2(0,48)
                joueur.vehicule_ref = null
            else:
                for v in veh.vehicules:
                    if joueur.position.distance_to(v.position) < 110.0:
                        joueur.en_vehicule = true
                        joueur.vehicule_ref = v
                        joueur.corps_visuel.visible = false
                        joueur.position = v.position
                        hud.msg_label.text = "🚙 " + v.get_meta("nom")
                        break
        elif event.scancode == KEY_G:
            for a in pop.allies:
                if not a.get_meta("recrute") and joueur.position.distance_to(a.position) < 220.0: a.set_meta("recrute", true); audio.p_ok.play(); hud.msg_label.text = "🤝 Survivant recruté !"; break
        elif event.scancode == KEY_F5:
            var f = File.new(); f.open("user://save_caillou.json", File.WRITE); f.store_string(to_json({"x": joueur.position.x, "y": joueur.position.y, "bois": bois, "metal": metal, "pv": joueur.pv, "vague": vague})); f.close(); audio.p_ok.play(); hud.msg_label.text = "💾 Sauvegardé !"
        elif event.scancode == KEY_F9:
            var f2 = File.new()
            if f2.open("user://save_caillou.json", File.READ) == OK:
                var d = parse_json(f2.get_as_text()); f2.close(); joueur.position = Vector2(d["x"], d["y"]); bois = d["bois"]; metal = d["metal"]; joueur.pv = d["pv"]; vague = d["vague"]; audio.p_ok.play(); hud.msg_label.text = "📂 Chargé !"
        elif event.scancode == KEY_X:
            hud.msg_label.text = eco.poser_explosif(joueur.position)
        elif event.scancode == KEY_K and not joueur.en_vehicule:
            hud.msg_label.text = eco.poser_coffre_qg(joueur.position)
        elif event.scancode == KEY_O and eco.coffre_pose and joueur.position.distance_to(eco.coffre_pos) < 120.0:
            if bois >= 50:
                bois -= 50; eco.coffre_bois += 50; hud.msg_label.text = "📦 +50 Bois déposés dans le Coffre QG (Total coffre: " + str(eco.coffre_bois) + ")"
            elif eco.coffre_bois >= 50:
                eco.coffre_bois -= 50; bois += 50; hud.msg_label.text = "📦 +50 Bois retirés du Coffre QG !"
        elif event.scancode == KEY_P:
            if eco.argent >= 1200:
                eco.argent -= 1200; eco.explosifs += 1; armes.reserve += 30; bidons += 1; audio.p_ok.play()
                hud.msg_label.text = "🏪 Achat Pack Survie (-1200 F) : +1 Explosif, +30 Balles, +1 Bidon ! (Solde: " + str(eco.argent) + " F)"
            else:
                hud.msg_label.text = "🏪 Solde insuffisant (" + str(eco.argent) + " F / 1200 F requis). Élimine des ennemis ou fais des missions !"
        elif event.scancode == KEY_F1:
            joueur.position = Vector2(0, 0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Nouméa (Anse Vata)"
        elif event.scancode == KEY_F2:
            joueur.position = Vector2(-2404668.3, -2049300.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Koné / Pouembout"
        elif event.scancode == KEY_F3:
            joueur.position = Vector2(-1440327.9, -1209450.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚁 Voyage rapide : Bourail"
        elif event.scancode == KEY_F4:
            joueur.position = Vector2(1593749.1, 599775.0); hud.carte_panel.visible = false; hud.msg_label.text = "🚤 Voyage rapide : Île des Pins (Kuto)"
        elif event.scancode == KEY_F6:
            joueur.position = Vector2(1209509.1, -2284920.0); hud.carte_panel.visible = false; hud.msg_label.text = "🛩️ Voyage rapide : Lifou (Wé)"
        elif event.scancode == KEY_Y:
            if pnj.pnj_actuel != null and joueur.position.distance_to(pnj.pnj_actuel.position) < 160.0:
                hud.msg_label.text = pnj.obtenir_dialogue(monde.mission_num) + " | Objectif : " + monde.mission_titre
                audio.p_ok.play()
            else:
                hud.msg_label.text = "🗣️ Approche-toi d'un PNJ (veste orange près de la balise jaune) et appuie sur [Y] !"
        elif event.scancode == KEY_1: outil = 1
        elif event.scancode == KEY_2: outil = 2
        elif event.scancode == KEY_3: outil = 3
