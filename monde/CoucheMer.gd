extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_mer := {}
var _tri := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var c_pat := PoolColorArray([Color(0.88, 0.76, 0.50, 0.88), Color(0.88, 0.76, 0.50, 0.88), Color(0.88, 0.76, 0.50, 0.88)])
var c_bar := PoolColorArray([Color(0.24, 0.86, 0.86, 0.85), Color(0.24, 0.86, 0.86, 0.85), Color(0.24, 0.86, 0.86, 0.85)])
var c_haut := PoolColorArray([Color(0.18, 0.74, 0.82, 0.78), Color(0.18, 0.74, 0.82, 0.78), Color(0.18, 0.74, 0.82, 0.78)])
var c_plg := PoolColorArray([Color(0.94, 0.86, 0.58, 0.94), Color(0.94, 0.86, 0.58, 0.94), Color(0.94, 0.86, 0.58, 0.94)])
var c_plat := PoolColorArray([Color(0.11, 0.54, 0.72, 0.76), Color(0.11, 0.54, 0.72, 0.76), Color(0.11, 0.54, 0.72, 0.76)])
var c_tomb := PoolColorArray([Color(0.06, 0.25, 0.45, 0.84), Color(0.06, 0.25, 0.45, 0.84), Color(0.06, 0.25, 0.45, 0.84)])

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var r_cel : int = int(clamp(ceil((2600.0 * z_act) / 16000.0), 2, 16))
    var gx : int = int(floor(centre.x / 16000.0)); var gy : int = int(floor(centre.y / 16000.0))
    for dx in range(-r_cel, r_cel + 1):
        for dy in range(-r_cel, r_cel + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_mer.has(k):
                for a in grille_mer[k]:
                    var b := Array(a)
                    if b.size() < 6: continue
                    _tri.set(0, Vector2(b.pop_front(), b.pop_front())); _tri.set(1, Vector2(b.pop_front(), b.pop_front())); _tri.set(2, Vector2(b.pop_front(), b.pop_front()))
                    var eb : int = b.pop_front()
                    var col := c_bar if eb == 1 else (c_haut if eb == 2 else (c_plg if eb == 3 else (c_plat if eb == 4 else (c_tomb if eb == 5 else c_pat))))
                    draw_primitive(_tri, col, PoolVector2Array())
