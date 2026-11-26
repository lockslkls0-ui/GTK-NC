extends Node2D
func charger_tex(chemin : String) -> ImageTexture:
    var img = Image.new()
    if img.load(chemin) != OK: return null
    var tex = ImageTexture.new()
    tex.create_from_image(img)
    return tex

var vehicules := []
var pompes := []
var fumees := []
var herses := []

func ajouter_veh(nom : String, places : int, vit : float, coul : Color, w : float, h : float, pos : Vector2):
    var v = Node2D.new()
    v.position = pos
    var car = Polygon2D.new()
    car.polygon = PoolVector2Array([Vector2(-w,-h), Vector2(w,-h), Vector2(w,h), Vector2(-w,h)])
    car.color = coul
    v.add_child(car)
    var pare = Polygon2D.new(); pare.polygon = PoolVector2Array([Vector2(w*0.2,-h*0.75), Vector2(w*0.55,-h*0.75), Vector2(w*0.55,h*0.75), Vector2(w*0.2,h*0.75)]); pare.color = Color(0.35, 0.78, 0.95); v.add_child(pare)
    var f_tex = "pickup.png"
    if "Bateau" in nom or "Vedette" in nom: f_tex = "bateau.png"
    elif "Hélicoptère" in nom: f_tex = "helico.png"
    elif "Moto" in nom: f_tex = "moto.png"
    var tv = charger_tex("res://assets/" + f_tex)
    if tv != null:
        car.visible = false; pare.visible = false; var sp_v = Sprite.new(); sp_v.texture = tv; v.add_child(sp_v)
    v.z_index = 6
    v.set_meta("nom", nom)
    v.set_meta("places", places)
    v.set_meta("vit", vit)
    v.set_meta("vit_max", vit)
    v.set_meta("essence", 100.0)
    add_child(v)
    vehicules.append(v)

func generer_flotte_et_stations():
    ajouter_veh("Pick-up 4x4", 8, 760.0, Color(0.92,0.92,0.95), 46, 24, Vector2(140, -110))
    ajouter_veh("Minibus Escouade", 12, 650.0, Color(0.25,0.45,0.75), 58, 26, Vector2(260, -110))
    ajouter_veh("Moto Cross", 2, 940.0, Color(0.90,0.28,0.15), 28, 12, Vector2(80, -160))
    ajouter_veh("Bateau Hors-Bord", 6, 820.0, Color(0.95,0.95,1.0), 52, 20, Vector2(-320, 260))
    ajouter_veh("Vedette Rapide Lagon", 8, 880.0, Color(0.15,0.55,0.85), 58, 22, Vector2(-460, 380))
    ajouter_veh("Bateau Pêcheur NC", 4, 720.0, Color(0.85,0.45,0.15), 48, 22, Vector2(-620, 510))
    ajouter_veh("Hélicoptère", 5, 3200.0, Color(0.25,0.28,0.32), 48, 18, Vector2(320, -240))

    for idx_v in range(28):
        var p_rand = Vector2(rand_range(-1400, 4200), rand_range(-7800, 1500))
        if idx_v % 3 == 0: ajouter_veh("Pick-up 4x4", 8, 760.0, Color(0.92,0.92,0.95), 46, 24, p_rand)
        elif idx_v % 3 == 1: ajouter_veh("Berline Civile", 4, 720.0, Color(0.25,0.45,0.75), 42, 20, p_rand)
        else: ajouter_veh("Moto Cross", 2, 940.0, Color(0.90,0.28,0.15), 28, 12, p_rand)
    var pos_stations = [Vector2(-240, -240), Vector2(850, -650), Vector2(-950, 720), Vector2(1450, 1100)]
    for sp in pos_stations:
        var dalle = Polygon2D.new()
        dalle.position = sp
        dalle.polygon = PoolVector2Array([Vector2(-90,-60), Vector2(90,-60), Vector2(90,60), Vector2(-90,60)])
        dalle.color = Color(0.32, 0.34, 0.38)
        add_child(dalle)
        for dx in [-35, 35]:
            var pompe = Node2D.new()
            pompe.position = sp + Vector2(dx, 0)
            var vis = Polygon2D.new()
            vis.polygon = PoolVector2Array([Vector2(-12,-12), Vector2(12,-12), Vector2(12,12), Vector2(-12,12)])
            vis.color = Color(0.92, 0.22, 0.18)
            pompe.add_child(vis)
            pompe.set_meta("intacte", true)
            add_child(pompe)
            pompes.append(pompe)

func verifier_explosion_pompe(pos_balle : Vector2, ennemis : Array, joueur : KinematicBody2D) -> String:
    for p in pompes:
        if p.get_meta("intacte") and pos_balle.distance_to(p.position) < 28.0:
            p.set_meta("intacte", false)
            p.get_child(0).color = Color(0.12, 0.12, 0.12)
            for j in range(ennemis.size() - 1, -1, -1):
                if ennemis[j].position.distance_to(p.position) < 260.0:
                    ennemis[j].queue_free()
                    ennemis.remove(j)
            if joueur.position.distance_to(p.position) < 220.0:
                joueur.pv = max(0.0, joueur.pv - 40.0)
            for _f in range(14):
                var fum = Polygon2D.new()
                fum.polygon = PoolVector2Array([Vector2(-35,-25), Vector2(35,-25), Vector2(35,25), Vector2(-35,25)])
                fum.color = Color(0.08, 0.08, 0.08, 0.65)
                fum.position = p.position + Vector2(rand_range(-70, 70), rand_range(-70, 70))
                add_child(fum)
                fumees.append(fum)
            return "💥 EXPLOSION DE LA POMPE À ESSENCE ! Fumée noire et dégâts de zone !"
    return ""

func faire_le_plein(pos_joueur : Vector2, vehicule_actuel : Node2D, bidons : int) -> Dictionary:
    if vehicule_actuel == null:
        return {"ok": false, "bidons": bidons, "msg": "⛽ Monte d'abord dans un véhicule [F] pour faire le plein."}
    for p in pompes:
        if p.get_meta("intacte") and pos_joueur.distance_to(p.position) < 150.0:
            vehicule_actuel.set_meta("essence", 100.0)
            return {"ok": true, "bidons": bidons, "msg": "⛽ Réservoir rempli à 100 % à la station-service !"}
    if bidons > 0:
        vehicule_actuel.set_meta("essence", min(100.0, vehicule_actuel.get_meta("essence") + 50.0))
        return {"ok": true, "bidons": bidons - 1, "msg": "🛢️ Bidon utilisé : +50 % d'essence !"}
    return {"ok": false, "bidons": bidons, "msg": "⛽ Approche d'une pompe rouge ou trouve un bidon [E] pour faire le plein [T]."}
