extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_lacs := {}; var grille_rivs := {}
var _tri := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var c_lac := PoolColorArray([Color(0.10, 0.44, 0.76, 0.94), Color(0.10, 0.44, 0.76, 0.94), Color(0.10, 0.44, 0.76, 0.94)])
var c_mar := PoolColorArray([Color(0.14, 0.46, 0.54, 0.85), Color(0.14, 0.46, 0.54, 0.85), Color(0.14, 0.46, 0.54, 0.85)])
var c_pis := PoolColorArray([Color(0.24, 0.82, 0.96, 0.96), Color(0.24, 0.82, 0.96, 0.96), Color(0.24, 0.82, 0.96, 0.96)])

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var r_cel : int = int(clamp(ceil((2600.0 * z_act) / 16000.0), 2, 16))
    var gx : int = int(floor(centre.x / 16000.0)); var gy : int = int(floor(centre.y / 16000.0))
    var col_r := Color(0.14, 0.56, 0.88, 0.92)
    for dx in range(-r_cel, r_cel + 1):
        for dy in range(-r_cel, r_cel + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_lacs.has(k):
                for it in grille_lacs[k]:
                    var a := Array(it)
                    if a.size() < 6: continue
                    _tri.set(0, Vector2(a.pop_front(), a.pop_front())); _tri.set(1, Vector2(a.pop_front(), a.pop_front())); _tri.set(2, Vector2(a.pop_front(), a.pop_front()))
                    var cd : int = a.pop_front()
                    draw_primitive(_tri, c_pis if cd == 3 else (c_mar if cd == 2 else c_lac), PoolVector2Array())
            if grille_rivs.has(k):
                for rv in grille_rivs[k]:
                    var b := Array(rv);
                    if b.size() < 3: continue; var pa : Vector2 = b.pop_front(); var pb : Vector2 = b.pop_front(); var lg : float = b.pop_front()
                    draw_line(pa, pb, col_r, clamp(max(lg * 0.65, z_act * 2.8), 28.0, 130.0))
