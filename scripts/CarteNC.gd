extends Node2D

var points_routes := []
var points_cotes := []
var lieux_nommes := []
var nb_batiments := 0
var centres_batiments := []

var tous_tris := []
var routes_nationales := []
var routes_locales := []
var toutes_forets := []
var tous_bats := []
var corps_collisions_actifs := []
var dernier_pos_maj := Vector2(999999, 999999)
var dernier_zoom_maj := -1.0
var police_carte : Font

func construire_carte(_chemin_json : String):
    var lat0 := -22.3015
    var lon0 := 166.4410
    var echelle := 1650000.0
    police_carte = Control.new().get_font("font")

    # 1. Charger la carte parfaite scellée (41 557 triangles côtiers)
    var f_ter = File.new()
    if f_ter.open("res://terrain_scelle_rapide.json", File.READ) == OK:
        var j_ter = JSON.parse(f_ter.get_as_text())
        f_ter.close()
        if j_ter.error == OK and typeof(j_ter.result) == TYPE_DICTIONARY:
            var idx := 0
            for t in j_ter.result.get("tris", []):
                var a := Array(t)
                var cx : float = a.pop_front()
                var cy : float = a.pop_front()
                var p0 := Vector2(a.pop_front(), a.pop_front())
                var p1 := Vector2(a.pop_front(), a.pop_front())
                var p2 := Vector2(a.pop_front(), a.pop_front())
                if abs((p1 - p0).cross(p2 - p0)) > 80.0:
                    tous_tris.append([Vector2(cx, cy), PoolVector2Array([p0, p1, p2])])
                    if idx % 5 == 0:
                        points_cotes.append(p0)
                    idx += 1

    # 2. Charger TOUTES les 118 050 routes, 2 291 forêts et 86 714 bâtiments de toute la Nouvelle-Calédonie
    var f_c = File.new()
    if f_c.open("res://couches_completes_nc.json", File.READ) == OK:
        var jc = JSON.parse(f_c.get_as_text())
        f_c.close()
        if jc.error == OK and typeof(jc.result) == TYPE_DICTIONARY:
            var ir := 0
            for r in jc.result.get("routes", []):
                var ar := Array(r)
                var pa := Vector2(ar.pop_front(), ar.pop_front())
                var pb := Vector2(ar.pop_front(), ar.pop_front())
                var lg : float = ar.pop_front()
                if true:
                    routes_nationales.append([pa, pb, lg])
                else:
                    routes_locales.append([pa, pb, lg])
                if ir % 15 == 0:
                    points_routes.append(pa)
                ir += 1
            for fo in jc.result.get("forets", []):
                var af := Array(fo)
                var fx : float = af.pop_front()
                var fy : float = af.pop_front()
                var fw : float = af.pop_front()
                var fh : float = af.pop_front()
                if fw < 3200.0 and fh < 3200.0:
                    toutes_forets.append(Rect2(fx, fy, fw, fh))
            for b in jc.result.get("bats", []):
                var ab := Array(b)
                var bx : float = ab.pop_front()
                var by : float = ab.pop_front()
                var bw : float = ab.pop_front()
                var bh : float = ab.pop_front()
                var cb := Vector2(bx, by)
                tous_bats.append([cb, Vector2(bw, bh)])
                nb_batiments += 1
                centres_batiments.append(cb)

    # 3. Charger les 1 111 noms officiels (communes, quartiers, tribus, montagnes, forêts, rivières)
    var f_topo = File.new()
    if f_topo.open("res://nc_toponymes.json", File.READ) == OK:
        var j_topo = JSON.parse(f_topo.get_as_text())
        f_topo.close()
        if j_topo.error == OK and typeof(j_topo.result) == TYPE_DICTIONARY:
            for t in j_topo.result.get("toponymes", []):
                var pos_t = Vector2((float(t["lon"]) - lon0) * echelle * cos(deg2rad(lat0)), -(float(t["lat"]) - lat0) * echelle)
                var cat = str(t.get("cat", "lieu"))
                lieux_nommes.append({"nom": t["nom"], "cat": cat, "pos": pos_t})
                if cat == "commune":
                    var lbl_t = Label.new()
                    lbl_t.text = "📍 " + str(t["nom"]).to_upper()
                    lbl_t.rect_position = pos_t
                    lbl_t.add_color_override("font_color", Color(1.0, 0.90, 0.25))
                    add_child(lbl_t)
    update()

func _process(_delta):
    var j = get_parent().get_node_or_null("Joueur")
    if j == null:
        return
    var z_act = 1.0
    if j.cam != null: z_act = j.cam.zoom.x
    if j.position.distance_to(dernier_pos_maj) > 250.0 or abs(z_act - dernier_zoom_maj) > 0.15:
        dernier_pos_maj = j.position
        dernier_zoom_maj = z_act
        for c in corps_collisions_actifs:
            if is_instance_valid(c): c.queue_free()
        corps_collisions_actifs.clear()
        for rb in tous_bats:
            var a := Array(rb)
            var ctr : Vector2 = a.pop_front()
            var dem : Vector2 = a.pop_front()
            if ctr.distance_to(j.position) < 2000.0:
                var sb = StaticBody2D.new()
                sb.position = ctr
                var cs = CollisionShape2D.new()
                var sh = RectangleShape2D.new()
                sh.extents = dem
                cs.shape = sh
                sb.add_child(cs)
                add_child(sb)
                corps_collisions_actifs.append(sb)
        update()

func _draw():
    var centre := dernier_pos_maj if dernier_pos_maj.x < 900000.0 else Vector2.ZERO
    var j = get_parent().get_node_or_null("Joueur")
    var zoom_act = 1.0
    if j != null and j.cam != null: zoom_act = j.cam.zoom.x
    var rayon_vue := max(25000.0, 2200.0 * zoom_act)

    # 1. Toute la Nouvelle-Calédonie (Grande Terre + Îles Loyauté + Bélep + Île des Pins)
    var col_terre := Color(0.22, 0.42, 0.20)
    for t in tous_tris:
        var a := Array(t)
        a.pop_front()
        draw_colored_polygon(a.pop_front(), col_terre)

    # 2. Forêts visibles dans le champ de caméra
    var col_foret := Color(0.11, 0.28, 0.12, 0.78)
    for rf in toutes_forets:
        if rf.position.distance_to(centre) < rayon_vue * 1.4:
            draw_rect(rf, col_foret)

    # 3. Réseau routier intégral sans débordement OpenGL (100% détail près de la caméra + 100% continuité en vue satellite)
    var col_route := Color(0.20, 0.21, 0.24)
    var larg_nat := max(85.0, zoom_act * 4.2)
    var pas_route := 1
    if zoom_act > 18.0:
        pas_route = 4
    elif zoom_act > 8.0:
        pas_route = 2
    var ir_draw := 0
    var col_piste := Color(0.58, 0.36, 0.22)
    for r in routes_nationales:
        var a := Array(r)
        var pa : Vector2 = a.pop_front()
        var pb : Vector2 = a.pop_front()
        var lg_orig : float = a.pop_front()
        if lg_orig <= 35.0:
            if pa.distance_to(centre) < 16000.0 and zoom_act < 14.0:
                draw_line(pa, pb, col_piste, max(26.0, zoom_act * 2.0))
        elif pa.distance_to(centre) < 32000.0 or (ir_draw % pas_route == 0):
            draw_line(pa, pb, col_route, larg_nat)
        ir_draw += 1

    # 4. Rues et routes locales autour de la caméra
    var larg_loc := max(44.0, zoom_act * 2.2)
    for r2 in routes_locales:
        var a2 := Array(r2)
        var pa2 : Vector2 = a2.pop_front()
        var pb2 : Vector2 = a2.pop_front()
        if pa2.distance_to(centre) < rayon_vue:
            draw_line(pa2, pb2, col_route, larg_loc)

    # 5. Bâtiments en 2.5D propres (ombres, murs en élévation et toits variés)
    var demi_min := clamp(zoom_act * 0.55, 2.5, 16.0)
    var col_ombre_b := Color(0.05, 0.08, 0.06, 0.42)
    var col_mur_b := Color(0.42, 0.40, 0.37)
    var col_t0 := Color(0.82, 0.54, 0.40)
    var col_t1 := Color(0.72, 0.76, 0.80)
    var col_t2 := Color(0.32, 0.54, 0.74)
    var col_t3 := Color(0.76, 0.36, 0.28)
    var ib := 0
    for rb in tous_bats:
        var a := Array(rb)
        var ctr : Vector2 = a.pop_front()
        var dem : Vector2 = a.pop_front()
        var d := Vector2(max(dem.x * 1.05, demi_min), max(dem.y * 1.05, demi_min))
        var col_toit := col_t0 if (ib % 4 == 0) else (col_t1 if (ib % 4 == 1) else (col_t2 if (ib % 4 == 2) else col_t3))
        if zoom_act < 3.5 and ctr.distance_to(centre) < 5500.0:
            var h_b := 8.0 + float((ib * 7) % 14)
            draw_rect(Rect2(ctr - d + Vector2(h_b * 0.65, h_b * 0.75), d * 2.0), col_ombre_b)
            draw_rect(Rect2(ctr - d, d * 2.0), col_mur_b)
            draw_rect(Rect2(ctr - d - Vector2(h_b * 0.35, h_b * 0.70), d * 2.0), col_toit)
        else:
            draw_rect(Rect2(ctr - d, d * 2.0), col_toit)
        ib += 1

    # 6. Noms locaux autour du joueur
    if police_carte != null:
        for l in lieux_nommes:
            if l["pos"].distance_to(centre) < rayon_vue * 0.7 and l.get("cat", "") != "commune":
                draw_string(police_carte, l["pos"], str(l["nom"]), Color(0.95, 0.95, 0.85))
