extends Node

static func dessiner(n : Node2D, ctr : Vector2, z : float, g_routes : Dictionary, g_bats : Dictionary, g_arbres : Dictionary, pois : Array, lieux : Array, pol : Font):
    var gx := int(floor(ctr.x / 12000.0)); var gy := int(floor(ctr.y / 12000.0))
    var rc : int = int(clamp(ceil(z * 0.35), 1, 8))
    var c_rt := Color(0.18, 0.19, 0.22); var c_pi := Color(0.68, 0.44, 0.24, 0.90)
    var c_omb := Color(0.05, 0.08, 0.06, 0.42); var c_mur := Color(0.42, 0.40, 0.37); var c_toit := Color(0.82, 0.54, 0.40)
    var l_nat : float = clamp(z * 5.5, 85.0, 220.0); var d_min : float = clamp(z * 0.55, 2.5, 16.0)
    for dx in range(-rc, rc + 1):
        for dy in range(-rc, rc + 1):
            var k := str(gx + dx) + "_" + str(gy + dy)
            if g_routes.has(k):
                for r in g_routes[k]:
                    var ar := Array(r); var pa : Vector2 = ar.pop_front(); var pb : Vector2 = ar.pop_front(); var lg : float = ar.pop_front()
                    if lg <= 35.0:
                        if z < 24.0: n.draw_line(pa, pb, c_pi, clamp(z * 2.4, 28.0, 75.0))
                    else: n.draw_line(pa, pb, c_rt, l_nat)
            if g_bats.has(k):
                for b in g_bats[k]:
                    var ab := Array(b); var cb : Vector2 = ab.pop_front(); var dm : Vector2 = ab.pop_front()
                    var d := Vector2(max(dm.x * 1.05, d_min), max(dm.y * 1.05, d_min))
                    if z < 3.5 and cb.distance_to(ctr) < 5500.0:
                        n.draw_rect(Rect2(cb - d + Vector2(8, 10), d * 2.0), c_omb)
                        n.draw_rect(Rect2(cb - d, d * 2.0), c_mur)
                        n.draw_rect(Rect2(cb - d - Vector2(4, 9), d * 2.0), c_toit)
                    else: n.draw_rect(Rect2(cb - d, d * 2.0), c_toit)
    if z < 4.5:
        var ax := int(floor(ctr.x / 6000.0)); var ay := int(floor(ctr.y / 6000.0))
        for dx in [-1, 0, 1]:
            for dy in [-1, 0, 1]:
                var ka := str(ax + dx) + "_" + str(ay + dy)
                if g_arbres.has(ka):
                    for ar in g_arbres[ka]:
                        var aa := Array(ar); var ap : Vector2 = aa.pop_front(); var ry : float = aa.pop_front()
                        if ap.distance_to(ctr) < 4800.0:
                            n.draw_circle(ap + Vector2(ry * 0.45, ry * 0.55), ry * 0.95, Color(0.04, 0.08, 0.04, 0.38))
                            n.draw_circle(ap, ry, Color(0.10, 0.34, 0.12))
                            n.draw_circle(ap + Vector2(-ry * 0.25, -ry * 0.25), ry * 0.52, Color(0.24, 0.54, 0.18, 0.85))
    var s_ico : float = clamp(z * 7.5, 16.0, 72.0); var r_vue : float = max(25000.0, 2200.0 * z)
    for po in pois:
        var apo := Array(po); var pp : Vector2 = apo.pop_front()
        if pp.distance_to(ctr) < r_vue * 1.25:
            var cat : String = apo.pop_front()
            n.draw_circle(pp + Vector2(3, 4), s_ico * 1.05, Color(0.03, 0.04, 0.06, 0.55))
            if cat == "hopital":
                n.draw_circle(pp, s_ico, Color(0.88, 0.14, 0.16)); n.draw_circle(pp, s_ico * 0.84, Color(0.98, 0.98, 0.99))
                n.draw_rect(Rect2(pp - Vector2(s_ico * 0.52, s_ico * 0.18), Vector2(s_ico * 1.04, s_ico * 0.36)), Color(0.88, 0.12, 0.14))
                n.draw_rect(Rect2(pp - Vector2(s_ico * 0.18, s_ico * 0.52), Vector2(s_ico * 0.36, s_ico * 1.04)), Color(0.88, 0.12, 0.14))
            elif cat == "police":
                n.draw_circle(pp, s_ico, Color(0.95, 0.96, 1.0)); n.draw_circle(pp, s_ico * 0.84, Color(0.10, 0.32, 0.78))
                n.draw_rect(Rect2(pp - Vector2(s_ico * 0.36, s_ico * 0.36), Vector2(s_ico * 0.72, s_ico * 0.72)), Color(0.98, 0.82, 0.18))
            elif cat == "station":
                n.draw_circle(pp, s_ico, Color(0.98, 0.95, 0.90)); n.draw_circle(pp, s_ico * 0.84, Color(0.94, 0.34, 0.10))
                n.draw_rect(Rect2(pp - Vector2(s_ico * 0.34, s_ico * 0.46), Vector2(s_ico * 0.62, s_ico * 0.92)), Color(0.98, 0.96, 0.92))
            else:
                n.draw_circle(pp, s_ico, Color(0.98, 0.96, 0.90)); n.draw_circle(pp, s_ico * 0.84, Color(0.92, 0.64, 0.12))
                n.draw_rect(Rect2(pp - Vector2(s_ico * 0.48, s_ico * 0.36), Vector2(s_ico * 0.96, s_ico * 0.28)), Color(0.86, 0.20, 0.18))
