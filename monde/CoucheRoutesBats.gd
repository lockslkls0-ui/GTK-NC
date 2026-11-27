extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_routes := {}; var grille_bats := {}
var points_routes := Array(); var centres_batiments := Array()
var nb_batiments := 0; var corps_actifs := Array()

func maj_collisions(pos_j : Vector2):
    for c in corps_actifs:
        if is_instance_valid(c): c.queue_free()
    corps_actifs.clear()
    var gx := int(floor(pos_j.x / 16000.0)); var gy := int(floor(pos_j.y / 16000.0))
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            var cl := str(gx + dx) + "_" + str(gy + dy)
            if grille_bats.has(cl):
                for rb in grille_bats[cl]:
                    var a := Array(rb)
                    if a.size() < 2: continue
                    var ctr : Vector2 = a.pop_front(); var dem : Vector2 = a.pop_front()
                    if ctr.distance_to(pos_j) < 2000.0:
                        var sb := StaticBody2D.new(); sb.position = ctr
                        var cs := CollisionShape2D.new(); var sh := RectangleShape2D.new(); sh.extents = dem
                        cs.shape = sh; sb.add_child(cs); add_child(sb); corps_actifs.append(sb)

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var r_cel : int = int(clamp(ceil((2600.0 * z_act) / 16000.0), 1, 14))
    var gx : int = int(floor(centre.x / 16000.0)); var gy : int = int(floor(centre.y / 16000.0))
    var c_rt := Color(0.18, 0.19, 0.22); var c_pi := Color(0.68, 0.44, 0.24, 0.90)
    var c_omb := Color(0.05, 0.08, 0.06, 0.42); var c_mur := Color(0.42, 0.40, 0.37); var c_toit := Color(0.82, 0.54, 0.40)
    var l_nat : float = clamp(z_act * 5.5, 85.0, 220.0); var d_min : float = clamp(z_act * 0.55, 2.5, 16.0)
    for dx in range(-r_cel, r_cel + 1):
        for dy in range(-r_cel, r_cel + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_routes.has(k):
                for r in grille_routes[k]:
                    var a := Array(r)
                    if a.size() < 3: continue
                    var pa : Vector2 = a.pop_front(); var pb : Vector2 = a.pop_front(); var lg : float = a.pop_front()
                    if lg <= 35.0:
                        if z_act < 24.0: draw_line(pa, pb, c_pi, clamp(z_act * 2.4, 28.0, 75.0))
                    else: draw_line(pa, pb, c_rt, l_nat)
            if grille_bats.has(k):
                for rb in grille_bats[k]:
                    var ab := Array(rb)
                    if ab.size() < 2: continue
                    var ctr : Vector2 = ab.pop_front(); var dem : Vector2 = ab.pop_front()
                    var d := Vector2(max(dem.x * 1.05, d_min), max(dem.y * 1.05, d_min))
                    if z_act < 3.5 and ctr.distance_to(centre) < 5500.0:
                        draw_rect(Rect2(ctr - d + Vector2(8, 10), d * 2.0), c_omb)
                        draw_rect(Rect2(ctr - d, d * 2.0), c_mur)
                        draw_rect(Rect2(ctr - d - Vector2(4, 9), d * 2.0), c_toit)
                    else: draw_rect(Rect2(ctr - d, d * 2.0), c_toit)
