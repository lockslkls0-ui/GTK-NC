extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_arbres := {}; var secteurs_peuples := {}

func _cle(p : Vector2) -> String:
    return str(int(floor(p.x / 8000.0))) + "_" + str(int(floor(p.y / 8000.0)))

func peupler_autour(pos : Vector2):
    var gx := int(floor(pos.x / 2000.0)); var gy := int(floor(pos.y / 2000.0))
    var ajout := false
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var cs := str(gx + dx) + "_" + str(gy + dy)
            if not secteurs_peuples.has(cs):
                secteurs_peuples[cs] = true; ajout = true
                var c := Vector2((gx + dx) * 2000.0 + 1000.0, (gy + dy) * 2000.0 + 1000.0)
                for k in range(14):
                    var ang := float(k) * 0.45 + float(dx + dy)
                    var pa := c + Vector2(cos(ang), sin(ang)) * (160.0 + float((k * 67) % 780))
                    var cl := _cle(pa)
                    if not grille_arbres.has(cl): grille_arbres[cl] = Array()
                    var arb := Array(); arb.append(pa); arb.append(18.0 + float(k % 8)); arb.append(k % 3)
                    grille_arbres[cl].append(arb)
    if ajout: update()

func recolter_proche(pos_j : Vector2, rayon : float = 120.0) -> int:
    var gx := int(floor(pos_j.x / 8000.0)); var gy := int(floor(pos_j.y / 8000.0))
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var cl := str(gx + dx) + "_" + str(gy + dy)
            if grille_arbres.has(cl):
                var liste : Array = grille_arbres[cl]
                for i in range(liste.size() - 1, -1, -1):
                    var a := Array(liste[i]); var ap : Vector2 = a.pop_front()
                    if ap.distance_to(pos_j) <= rayon:
                        liste.remove(i); update(); return 5
    return 0

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    if j == null: return
    var z_act : float = j.cam.zoom.x if j.cam != null else 1.0
    if z_act > 4.2: return
    var c_omb := Color(0.04, 0.08, 0.04, 0.38); var c_lum := Color(0.24, 0.54, 0.18, 0.85)
    var c0 := Color(0.10, 0.34, 0.12); var c1 := Color(0.15, 0.42, 0.14); var c2 := Color(0.08, 0.28, 0.11)
    var gx := int(floor(centre_vue.x / 8000.0)); var gy := int(floor(centre_vue.y / 8000.0))
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var cl := str(gx + dx) + "_" + str(gy + dy)
            if grille_arbres.has(cl):
                for it in grille_arbres[cl]:
                    var a := Array(it)
                    if a.size() < 3: continue
                    var ap : Vector2 = a.pop_front()
                    if ap.distance_to(centre_vue) < 4800.0:
                        var ray : float = a.pop_front(); var vc : int = a.pop_front()
                        var col_a := c0 if (vc % 3) == 0 else (c1 if (vc % 3) == 1 else c2)
                        draw_circle(ap + Vector2(ray * 0.45, ray * 0.55), ray * 0.95, c_omb)
                        draw_circle(ap, ray, col_a)
                        draw_circle(ap + Vector2(-ray * 0.25, -ray * 0.25), ray * 0.52, c_lum)
