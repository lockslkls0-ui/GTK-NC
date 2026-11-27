extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var tous_sommets := Array()
var police : Font

func charger(f_font : Font):
    z_index = -7
    police = f_font
    var f = File.new()
    if f.open("res://rivieres_et_sommets_nc.json", File.READ) == OK:
        var j = JSON.parse(f.get_as_text()); f.close()
        if j.error == OK and typeof(j.result) == TYPE_DICTIONARY:
            for sm in j.result.get("sommets", Array()):
                var a := Array(sm)
                if a.size() < 4: continue
                var it := Array()
                it.append(Vector2(a.pop_front(), a.pop_front())); it.append(str(a.pop_front())); it.append(str(a.pop_front()))
                tous_sommets.append(it)
    update()

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var rayon_vue : float = max(25000.0, 2200.0 * z_act)
    var c_plage := Color(0.92, 0.84, 0.58, 0.92)
    var larg_p : float = clamp(z_act * 18.0, 48.0, 240.0)
    var c_terre = get_parent().c_terre
    if c_terre != null:
        var pas := 1 if z_act <= 8.0 else 3
        var i := 0
        for sp in c_terre.segments_plages:
            var a := Array(sp)
            if a.size() >= 2:
                var pa : Vector2 = a.pop_front(); var pb : Vector2 = a.pop_front()
                if pa.distance_to(centre) < rayon_vue * 1.3 or (i % pas == 0): draw_line(pa, pb, c_plage, larg_p)
            i += 1
    for sm in tous_sommets:
        var a := Array(sm)
        if a.size() < 3: continue
        var sp : Vector2 = a.pop_front()
        if sp.distance_to(centre) < rayon_vue * 1.4:
            var rm : float = clamp(z_act * 22.0, 160.0, 500.0)
            draw_circle(sp, rm * 0.75, Color(0.46, 0.40, 0.32, 0.82))
            draw_circle(sp + Vector2(-rm * 0.15, -rm * 0.20), rm * 0.35, Color(0.66, 0.60, 0.52, 0.90))
