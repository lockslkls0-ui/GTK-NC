extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var grille_terre := {}; var segments_plages := Array(); var points_cotes := Array()
var _tri := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var c_terre := PoolColorArray([Color(0.22, 0.42, 0.20), Color(0.22, 0.42, 0.20), Color(0.22, 0.42, 0.20)])

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var r_cel : int = int(clamp(ceil((2600.0 * z_act) / 16000.0), 2, 22))
    var gx : int = int(floor(centre.x / 16000.0)); var gy : int = int(floor(centre.y / 16000.0))
    for dx in range(-r_cel, r_cel + 1):
        for dy in range(-r_cel, r_cel + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if grille_terre.has(k):
                for poly in grille_terre[k]:
                    var b := Array(poly)
                    if b.size() < 6: continue
                    _tri.set(0, Vector2(b.pop_front(), b.pop_front()))
                    _tri.set(1, Vector2(b.pop_front(), b.pop_front()))
                    _tri.set(2, Vector2(b.pop_front(), b.pop_front()))
                    draw_primitive(_tri, c_terre, PoolVector2Array())
