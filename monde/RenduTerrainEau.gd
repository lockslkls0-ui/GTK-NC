extends Node

static func dessiner(n : Node2D, ctr : Vector2, z : float, g_recifs : Dictionary, g_terre : Dictionary, g_relief : Dictionary, g_forets : Dictionary, g_lacs : Dictionary, g_rivs : Dictionary, sommets : Array, plages : Array, t_vagues : float, pol : Font):
    var _tri := PoolVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
    var gx := int(floor(ctr.x / 12000.0)); var gy := int(floor(ctr.y / 12000.0))
    var rc : int = int(clamp(ceil(z * 0.38), 1, 9))
    var c_bar := PoolColorArray([Color(0.24, 0.86, 0.86, 0.82), Color(0.24, 0.86, 0.86, 0.82), Color(0.24, 0.86, 0.86, 0.82)])
    var c_pat := PoolColorArray([Color(0.88, 0.76, 0.50, 0.85), Color(0.88, 0.76, 0.50, 0.85), Color(0.88, 0.76, 0.50, 0.85)])
    var c_haut := PoolColorArray([Color(0.18, 0.72, 0.80, 0.75), Color(0.18, 0.72, 0.80, 0.75), Color(0.18, 0.72, 0.80, 0.75)])
    var c_plg := PoolColorArray([Color(0.94, 0.86, 0.58, 0.94), Color(0.94, 0.86, 0.58, 0.94), Color(0.94, 0.86, 0.58, 0.94)])
    var c_ter := PoolColorArray([Color(0.22, 0.42, 0.20), Color(0.22, 0.42, 0.20), Color(0.22, 0.42, 0.20)])
    var c_for := PoolColorArray([Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82), Color(0.12, 0.30, 0.13, 0.82)])
    var c_lac := PoolColorArray([Color(0.10, 0.44, 0.76, 0.94), Color(0.10, 0.44, 0.76, 0.94), Color(0.10, 0.44, 0.76, 0.94)])
    var c_mar := PoolColorArray([Color(0.14, 0.46, 0.54, 0.85), Color(0.14, 0.46, 0.54, 0.85), Color(0.14, 0.46, 0.54, 0.85)])
    var c_pis := PoolColorArray([Color(0.24, 0.82, 0.96, 0.96), Color(0.24, 0.82, 0.96, 0.96), Color(0.24, 0.82, 0.96, 0.96)])
    for dx in range(-rc, rc + 1):
        for dy in range(-rc, rc + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if g_recifs.has(k):
                for it in g_recifs[k]:
                    var a := Array(it); _tri.set(0, a.pop_front()); _tri.set(1, a.pop_front()); _tri.set(2, a.pop_front()); var eb : int = a.pop_front()
                    n.draw_primitive(_tri, c_bar if eb == 1 else (c_haut if eb == 2 else (c_plg if eb == 3 else c_pat)), PoolVector2Array())
            if g_terre.has(k):
                for it in g_terre[k]:
                    var a := Array(it); _tri.set(0, a.pop_front()); _tri.set(1, a.pop_front()); _tri.set(2, a.pop_front())
                    n.draw_primitive(_tri, c_ter, PoolVector2Array())
            if g_forets.has(k):
                for it in g_forets[k]:
                    var a := Array(it); _tri.set(0, a.pop_front()); _tri.set(1, a.pop_front()); _tri.set(2, a.pop_front())
                    n.draw_primitive(_tri, c_for, PoolVector2Array())
            if g_lacs.has(k):
                for it in g_lacs[k]:
                    var a := Array(it); _tri.set(0, a.pop_front()); _tri.set(1, a.pop_front()); _tri.set(2, a.pop_front()); var cd : int = a.pop_front()
                    n.draw_primitive(_tri, c_pis if cd == 3 else (c_mar if cd == 2 else c_lac), PoolVector2Array())
            if g_rivs.has(k):
                for rv in g_rivs[k]:
                    var ar := Array(rv); var pa : Vector2 = ar.pop_front(); var pb : Vector2 = ar.pop_front(); var lg : float = ar.pop_front()
                    n.draw_line(pa, pb, Color(0.14, 0.56, 0.88, 0.92), clamp(max(lg * 0.65, z * 2.8), 28.0, 120.0))
