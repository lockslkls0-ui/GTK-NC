extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_relief := {}; var grille_forets := {}
var _tri := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var c_r1 := PoolColorArray([Color(0.26, 0.44, 0.18, 0.55), Color(0.26, 0.44, 0.18, 0.55), Color(0.26, 0.44, 0.18, 0.55)])
var c_r2 := PoolColorArray([Color(0.36, 0.40, 0.20, 0.68), Color(0.36, 0.40, 0.20, 0.68), Color(0.36, 0.40, 0.20, 0.68)])
var c_r3 := PoolColorArray([Color(0.48, 0.43, 0.34, 0.78), Color(0.48, 0.43, 0.34, 0.78), Color(0.48, 0.43, 0.34, 0.78)])
var c_r4 := PoolColorArray([Color(0.62, 0.26, 0.14, 0.68), Color(0.62, 0.26, 0.14, 0.68), Color(0.62, 0.26, 0.14, 0.68)])
var c_for := PoolColorArray([Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82)])

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var r_cel : int = int(clamp(ceil((2600.0 * z_act) / 16000.0), 2, 16))
    var gx : int = int(floor(centre.x / 16000.0)); var gy : int = int(floor(centre.y / 16000.0))
    for dx in range(-r_cel, r_cel + 1):
        for dy in range(-r_cel, r_cel + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_relief.has(k):
                for it in grille_relief[k]:
                    var a := Array(it)
                    if a.size() < 6: continue
                    _tri.set(0, Vector2(a.pop_front(), a.pop_front())); _tri.set(1, Vector2(a.pop_front(), a.pop_front())); _tri.set(2, Vector2(a.pop_front(), a.pop_front()))
                    var cd : int = a.pop_front()
                    draw_primitive(_tri, c_r4 if cd == 4 else (c_r3 if cd == 3 else (c_r2 if cd == 2 else c_r1)), PoolVector2Array())
            if grille_forets.has(k):
                for ft in grille_forets[k]:
                    var b := Array(ft)
                    if b.size() < 6: continue
                    _tri.set(0, Vector2(b.pop_front(), b.pop_front())); _tri.set(1, Vector2(b.pop_front(), b.pop_front())); _tri.set(2, Vector2(b.pop_front(), b.pop_front()))
                    draw_primitive(_tri, c_for, PoolVector2Array())
