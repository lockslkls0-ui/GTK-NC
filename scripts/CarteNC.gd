extends Node2D

var points_routes := []
var points_cotes := []
var lieux_nommes := []
var labels_communes := []
var nb_batiments := 0
var centres_batiments := []

var tous_tris := []
var routes_nationales := []
var routes_locales := []
var toutes_forets := []
var tous_arbres := []
var toutes_rivieres := []
var tous_sommets := []
var tris_relief := []
var tris_recifs := []
var segments_plages := []
var tous_bats := []
var corps_collisions_actifs := []
var dernier_pos_maj := Vector2(999999, 999999)
var dernier_zoom_maj := -1.0
var police_carte : Font
var temps_vagues := 0.0

func construire_carte(_chemin_json : String):
    var lat0 := -22.3015
    var lon0 := 166.4410
    var echelle := 1650000.0
    var ctrl_f = Control.new(); police_carte = ctrl_f.get_font("font", "Label"); ctrl_f.free()

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

    var f_rec = File.new()
    if f_rec.open("res://recifs_nc.json", File.READ) == OK:
        var j_rec = JSON.parse(f_rec.get_as_text())
        f_rec.close()
        if j_rec.error == OK and typeof(j_rec.result) == TYPE_DICTIONARY:
            for rec in j_rec.result.get("recifs", []):
                var ar := Array(rec)
                if ar.size() < 8:
                    continue
                var ctr := Vector2(ar.pop_front(), ar.pop_front())
                var p0 := Vector2(ar.pop_front(), ar.pop_front())
                var p1 := Vector2(ar.pop_front(), ar.pop_front())
                var p2 := Vector2(ar.pop_front(), ar.pop_front())
                var eb : int = int(ar.pop_front()) if ar.size() > 0 else 1
                tris_recifs.append(Array([ctr, p0, p1, p2, eb]))
    var f_ter2 = File.new()
    if f_ter2.open("res://terrain_scelle_rapide.json", File.READ) == OK:
        var j_ter2 = JSON.parse(f_ter2.get_as_text())
        f_ter2.close()
        if j_ter2.error == OK and typeof(j_ter2.result) == TYPE_DICTIONARY:
            for t in j_ter2.result.get("tris", []):
                var at := Array(t)
                if at.size() < 8: continue
                at.pop_front(); at.pop_front()
                var p0 := Vector2(at.pop_front(), at.pop_front())
                var p1 := Vector2(at.pop_front(), at.pop_front())
                var p2 := Vector2(at.pop_front(), at.pop_front())
                if p0.distance_to(p1) < 2800.0: segments_plages.append(Array([p0, p1]))
                if p1.distance_to(p2) < 2800.0: segments_plages.append(Array([p1, p2]))
    var f_rel = File.new()
    if f_rel.open("res://relief_nc_couches.json", File.READ) == OK:
        var j_rel = JSON.parse(f_rel.get_as_text())
        f_rel.close()
        if j_rel.error == OK and typeof(j_rel.result) == TYPE_DICTIONARY:
            for tr in j_rel.result.get("relief", []):
                var atr := Array(tr)
                if atr.size() >= 9:
                    tris_relief.append(Array([Vector2(atr.pop_front(), atr.pop_front()), Vector2(atr.pop_front(), atr.pop_front()), Vector2(atr.pop_front(), atr.pop_front()), Vector2(atr.pop_front(), atr.pop_front()), int(atr.pop_front())]))
    var f_for = File.new()
    if f_for.open("res://forets_et_arbres_nc.json", File.READ) == OK:
        var j_for = JSON.parse(f_for.get_as_text())
        f_for.close()
        if j_for.error == OK and typeof(j_for.result) == TYPE_DICTIONARY:
            toutes_forets.clear()
            for ft in j_for.result.get("forets_tris", []):
                var aft := Array(ft)
                if aft.size() >= 8:
                    var ctr := Vector2(aft.pop_front(), aft.pop_front())
                    var p0 := Vector2(aft.pop_front(), aft.pop_front())
                    var p1 := Vector2(aft.pop_front(), aft.pop_front())
                    var p2 := Vector2(aft.pop_front(), aft.pop_front())
                    toutes_forets.append(Array([ctr, p0, p1, p2]))
            for ar in j_for.result.get("arbres", []):
                var aar := Array(ar)
                if aar.size() >= 4:
                    tous_arbres.append(Array([Vector2(aar.pop_front(), aar.pop_front()), aar.pop_front(), int(aar.pop_front())]))
    var f_riv = File.new()
    if f_riv.open("res://rivieres_et_sommets_nc.json", File.READ) == OK:
        var j_riv = JSON.parse(f_riv.get_as_text())
        f_riv.close()
        if j_riv.error == OK and typeof(j_riv.result) == TYPE_DICTIONARY:
            for rv in j_riv.result.get("rivieres", []):
                var arv := Array(rv)
                var ra := Vector2(arv.pop_front(), arv.pop_front())
                var rb := Vector2(arv.pop_front(), arv.pop_front())
                var rlg : float = arv.pop_front() if arv.size() > 0 else 75.0
                toutes_rivieres.append(Array([ra, rb, rlg]))
            for sm in j_riv.result.get("sommets", []):
                var asm := Array(sm)
                var sp := Vector2(asm.pop_front(), asm.pop_front())
                var snom := str(asm.pop_front())
                var sele := str(asm.pop_front())
                tous_sommets.append(Array([sp, snom, sele]))
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
                    lbl_t.queue_free()
    update()

func _process(delta):
    temps_vagues += delta
    var j = get_parent().get_node_or_null("Joueur")
    if j == null:
        return
    var z_act = 1.0
    if j.cam != null: z_act = j.cam.zoom.x
    var sc_com = clamp(z_act * 0.85, 1.4, 24.0)
    for lc in labels_communes:
        lc.rect_scale = Vector2(sc_com, sc_com)
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

    # 0a. Plages dorées + Animation des vagues et de l'écume côtière
    var col_plage := Color(0.92, 0.84, 0.58, 0.92)
    var larg_plage := clamp(zoom_act * 18.0, 48.0, 260.0)
    var onde_vague := 0.5 + 0.5 * sin(temps_vagues * 2.1)
    var col_ecume := Color(0.92, 0.98, 1.0, 0.25 + 0.30 * onde_vague)
    var larg_ecume := larg_plage + 18.0 + 26.0 * onde_vague
    var pas_pl := 1 if zoom_act <= 8.0 else (2 if zoom_act <= 18.0 else 4)
    var ipl := 0
    for sp in segments_plages:
        var asp := Array(sp)
        var pa : Vector2 = asp.pop_front()
        var pb : Vector2 = asp.pop_front()
        if pa.distance_to(centre) < rayon_vue * 1.4 or (ipl % pas_pl == 0):
            if zoom_act < 6.0 and pa.distance_to(centre) < 9000.0:
                draw_line(pa, pb, col_ecume, larg_ecume)
            draw_line(pa, pb, col_plage, larg_plage)
        ipl += 1

    # 0b. Bathymétrie complète (Plateau lagon, Tombant barrière, Hauts-fonds, Récifs & Patates)
    var c_bar := PoolColorArray([Color(0.24, 0.86, 0.86, 0.82), Color(0.24, 0.86, 0.86, 0.82), Color(0.24, 0.86, 0.86, 0.82)])
    var c_pat := PoolColorArray([Color(0.88, 0.76, 0.50, 0.85), Color(0.88, 0.76, 0.50, 0.85), Color(0.88, 0.76, 0.50, 0.85)])
    var c_haut := PoolColorArray([Color(0.18, 0.72, 0.80, 0.75), Color(0.18, 0.72, 0.80, 0.75), Color(0.18, 0.72, 0.80, 0.75)])
    var c_plat := PoolColorArray([Color(0.10, 0.48, 0.66, 0.72), Color(0.10, 0.48, 0.66, 0.72), Color(0.10, 0.48, 0.66, 0.72)])
    var c_tomb := PoolColorArray([Color(0.07, 0.30, 0.48, 0.78), Color(0.07, 0.30, 0.48, 0.78), Color(0.07, 0.30, 0.48, 0.78)])
    for tr in tris_recifs:
        var atr := Array(tr)
        var ctr : Vector2 = atr.pop_front()
        if ctr.distance_to(centre) < rayon_vue * 1.55:
            var p0 : Vector2 = atr.pop_front()
            var p1 : Vector2 = atr.pop_front()
            var p2 : Vector2 = atr.pop_front()
            var eb : int = atr.pop_front()
            var col_use := c_bar if eb == 1 else (c_haut if eb == 2 else (c_plat if eb == 4 else (c_tomb if eb == 5 else c_pat)))
            draw_primitive(PoolVector2Array([p0, p1, p2]), col_use, PoolVector2Array())

    # 1. Toute la Nouvelle-Calédonie (Grande Terre + Îles Loyauté + Bélep + Île des Pins)
    var col_terre := Color(0.22, 0.42, 0.20)
    for t in tous_tris:
        var a := Array(t)
        a.pop_front()
        draw_colored_polygon(a.pop_front(), col_terre)

    # 1b. Relief topographique de la Chaîne Centrale & Terre rouge latéritique du Sud
    var c_rel_1 := PoolColorArray([Color(0.26, 0.44, 0.18, 0.55), Color(0.26, 0.44, 0.18, 0.55), Color(0.26, 0.44, 0.18, 0.55)])
    var c_rel_2 := PoolColorArray([Color(0.36, 0.40, 0.20, 0.68), Color(0.36, 0.40, 0.20, 0.68), Color(0.36, 0.40, 0.20, 0.68)])
    var c_rel_3 := PoolColorArray([Color(0.48, 0.43, 0.34, 0.78), Color(0.48, 0.43, 0.34, 0.78), Color(0.48, 0.43, 0.34, 0.78)])
    var c_rel_4 := PoolColorArray([Color(0.62, 0.26, 0.14, 0.68), Color(0.62, 0.26, 0.14, 0.68), Color(0.62, 0.26, 0.14, 0.68)])
    for tr in tris_relief:
        var atr := Array(tr)
        var ctr : Vector2 = atr.pop_front()
        if ctr.distance_to(centre) < rayon_vue * 1.6:
            var p0 : Vector2 = atr.pop_front()
            var p1 : Vector2 = atr.pop_front()
            var p2 : Vector2 = atr.pop_front()
            var code : int = atr.pop_front()
            var col_u := c_rel_4 if code == 4 else (c_rel_3 if code == 3 else (c_rel_2 if code == 2 else c_rel_1))
            draw_primitive(PoolVector2Array([p0, p1, p2]), col_u, PoolVector2Array())

    # 2. Massifs forestiers réels découpés au contour exact (0 débordement en mer)
    var c_for := PoolColorArray([Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82)])
    for ft in toutes_forets:
        var aft := Array(ft)
        var ctr : Vector2 = aft.pop_front()
        if ctr.distance_to(centre) < rayon_vue * 1.55:
            var p0 : Vector2 = aft.pop_front()
            var p1 : Vector2 = aft.pop_front()
            var p2 : Vector2 = aft.pop_front()
            draw_primitive(PoolVector2Array([p0, p1, p2]), c_for, PoolVector2Array())

    # 2a. Arbres 2.5D détaillés en vue rapprochée (ombre portée + feuillage en volume)
    if zoom_act < 3.2:
        var c_omb_a := Color(0.04, 0.08, 0.04, 0.38)
        var c_feu_0 := Color(0.10, 0.34, 0.12)
        var c_feu_1 := Color(0.15, 0.42, 0.14)
        var c_feu_2 := Color(0.08, 0.28, 0.11)
        var c_lum_a := Color(0.24, 0.54, 0.18, 0.85)
        for ar in tous_arbres:
            var aar := Array(ar)
            var ap : Vector2 = aar.pop_front()
            if ap.distance_to(centre) < 4800.0:
                var ray : float = aar.pop_front()
                var var_c : int = aar.pop_front()
                var col_f := c_feu_0 if var_c == 0 else (c_feu_1 if var_c == 1 else c_feu_2)
                draw_circle(ap + Vector2(ray * 0.45, ray * 0.55), ray * 0.95, c_omb_a)
                draw_circle(ap, ray, col_f)
                draw_circle(ap + Vector2(-ray * 0.25, -ray * 0.25), ray * 0.52, c_lum_a)

    # 2b. Fleuves, rivières et criques
    var col_riv := Color(0.14, 0.56, 0.88, 0.92)
    var pas_riv := 1 if zoom_act <= 8.0 else (2 if zoom_act <= 18.0 else 4)
    var iriv := 0
    for rv in toutes_rivieres:
        var arv := Array(rv)
        var ra : Vector2 = arv.pop_front()
        var rb : Vector2 = arv.pop_front()
        var rlg : float = arv.pop_front()
        if ra.distance_to(centre) < rayon_vue * 1.3 or (iriv % pas_riv == 0 and rlg >= 70.0):
            draw_line(ra, rb, col_riv, clamp(max(rlg * 0.65, zoom_act * 2.8), 32.0, 140.0))
        iriv += 1

    # 2c. Massifs et sommets montagneux avec noms et altitudes liés
    var col_m_ombre := Color(0.24, 0.20, 0.16, 0.55)
    var col_m_face := Color(0.46, 0.40, 0.32, 0.82)
    var col_m_cre := Color(0.66, 0.60, 0.52, 0.90)
    for sm in tous_sommets:
        var asm := Array(sm)
        var sp : Vector2 = asm.pop_front()
        var snom := str(asm.pop_front())
        var sele := str(asm.pop_front())
        if sp.distance_to(centre) < rayon_vue * 1.5:
            var rm := clamp(zoom_act * 22.0, 160.0, 520.0)
            draw_circle(sp + Vector2(rm * 0.25, rm * 0.20), rm * 0.85, col_m_ombre)
            draw_circle(sp, rm * 0.75, col_m_face)
            draw_circle(sp + Vector2(-rm * 0.15, -rm * 0.20), rm * 0.35, col_m_cre)
            if police_carte != null and zoom_act < 15.0 and snom != "" and snom != "Sommet":
                var lbl_s := snom + (" (" + sele + "m)" if sele != "" else "")
                draw_string(police_carte, sp + Vector2(-36, rm * 0.85 + 14), lbl_s, Color(1.0, 0.86, 0.55))

    # 3. Réseau routier intégral & sentiers de brousse (visibles de près comme en vue satellite)
    var col_route := Color(0.18, 0.19, 0.22)
    var col_bord := Color(0.75, 0.72, 0.65, 0.45)
    var larg_nat := clamp(zoom_act * 5.5, 85.0, 220.0)
    var pas_route := 1 if zoom_act <= 10.0 else (2 if zoom_act <= 22.0 else 3)
    var ir_draw := 0
    var col_piste := Color(0.68, 0.44, 0.24, 0.90)
    for r in routes_nationales:
        var a := Array(r)
        var pa : Vector2 = a.pop_front()
        var pb : Vector2 = a.pop_front()
        var lg_orig : float = a.pop_front()
        if lg_orig <= 35.0:
            if pa.distance_to(centre) < rayon_vue * 1.1 and zoom_act < 24.0:
                draw_line(pa, pb, col_piste, clamp(zoom_act * 2.4, 28.0, 75.0))
        elif pa.distance_to(centre) < rayon_vue * 1.4 or (ir_draw % pas_route == 0):
            if zoom_act < 4.0:
                draw_line(pa, pb, col_bord, larg_nat + 18.0)
            draw_line(pa, pb, col_route, larg_nat)
        ir_draw += 1

    # 4. Rues et routes locales autour de la caméra
    var larg_loc := clamp(zoom_act * 2.6, 44.0, 110.0)
    for r2 in routes_locales:
        var a2 := Array(r2)
        var pa2 : Vector2 = a2.pop_front()
        var pb2 : Vector2 = a2.pop_front()
        if pa2.distance_to(centre) < rayon_vue * 1.1:
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

    # 6. Noms intelligents selon le zoom : Communes au dézoom + Lieux précis au zoom
    if police_carte != null:
        var col_ombre_txt := Color(0.04, 0.06, 0.08, 0.90)
        var col_com_txt := Color(1.0, 0.90, 0.28)
        var col_lieu_txt := Color(0.98, 0.96, 0.88)
        var sc_com := clamp(zoom_act * 2.4, 2.2, 42.0)
        var sc_lieu := clamp(zoom_act * 1.4, 1.4, 7.5)
        for l in lieux_nommes:
            var lp : Vector2 = l["pos"]
            var est_com : bool = (l.get("cat", "") == "commune")
            if est_com:
                if zoom_act >= 1.6 and lp.distance_to(centre) < rayon_vue * 1.6:
                    var nom_c := str(l["nom"]).to_upper()
                    draw_set_transform(lp + Vector2(3.0 * zoom_act, 3.0 * zoom_act), 0.0, Vector2(sc_com, sc_com))
                    draw_string(police_carte, Vector2.ZERO, nom_c, col_ombre_txt)
                    draw_set_transform(lp, 0.0, Vector2(sc_com, sc_com))
                    draw_string(police_carte, Vector2.ZERO, nom_c, col_com_txt)
            elif zoom_act < 5.5 and lp.distance_to(centre) < 12000.0 * max(1.0, zoom_act):
                var nom_l := str(l["nom"])
                draw_set_transform(lp + Vector2(2.0, 2.0), 0.0, Vector2(sc_lieu, sc_lieu))
                draw_string(police_carte, Vector2.ZERO, nom_l, col_ombre_txt)
                draw_set_transform(lp, 0.0, Vector2(sc_lieu, sc_lieu))
                draw_string(police_carte, Vector2.ZERO, nom_l, col_lieu_txt)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
