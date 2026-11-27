extends Node2D

var centre_vue := Vector2.ZERO
var zoom_vue := 1.0

var tous_pois := Array()
var lieux_nommes := Array()
var police : Font

func charger(f_font : Font):
    z_index = 3
    police = f_font
    var lat0 := -22.3015; var lon0 := 166.4410; var ech := 1650000.0
    var f1 = File.new()
    if f1.open("res://pois_nc.json", File.READ) == OK:
        var j1 = JSON.parse(f1.get_as_text()); f1.close()
        if j1.error == OK and typeof(j1.result) == TYPE_DICTIONARY:
            for p in j1.result.get("pois", Array()):
                var item := Array()
                item.append(Vector2(p["x"], p["y"])); item.append(str(p["cat"])); item.append(str(p["nom"]))
                tous_pois.append(item)
    var f2 = File.new()
    if f2.open("res://nc_toponymes.json", File.READ) == OK:
        var j2 = JSON.parse(f2.get_as_text()); f2.close()
        if j2.error == OK and typeof(j2.result) == TYPE_DICTIONARY:
            for t in j2.result.get("toponymes", Array()):
                var pt := Vector2((float(t["lon"]) - lon0) * ech * cos(deg2rad(lat0)), -(float(t["lat"]) - lat0) * ech)
                lieux_nommes.append({"nom": t["nom"], "cat": str(t.get("cat", "lieu")), "pos": pt})
    update()

func _draw():
    var m = get_parent().get_parent(); var j = m.joueur if m != null else null
    var centre : Vector2 = centre_vue if j != null else Vector2.ZERO
    var z_act : float = j.cam.zoom.x if (j != null and j.cam != null) else 1.0
    var rayon_vue : float = max(25000.0, 2200.0 * z_act)
    var s_ico : float = clamp(z_act * 7.5, 16.0, 72.0)
    for po in tous_pois:
        var a := Array(po)
        if a.size() < 3: continue
        var pp : Vector2 = a.pop_front()
        if pp.distance_to(centre) < rayon_vue * 1.25:
            var cat : String = a.pop_front()
            draw_circle(pp + Vector2(3, 4), s_ico * 1.05, Color(0.03, 0.04, 0.06, 0.55))
            if cat == "hopital":
                draw_circle(pp, s_ico, Color(0.88, 0.14, 0.16)); draw_circle(pp, s_ico * 0.84, Color(0.98, 0.98, 0.99))
                draw_rect(Rect2(pp - Vector2(s_ico * 0.52, s_ico * 0.18), Vector2(s_ico * 1.04, s_ico * 0.36)), Color(0.88, 0.12, 0.14))
                draw_rect(Rect2(pp - Vector2(s_ico * 0.18, s_ico * 0.52), Vector2(s_ico * 0.36, s_ico * 1.04)), Color(0.88, 0.12, 0.14))
            elif cat == "police":
                draw_circle(pp, s_ico, Color(0.95, 0.96, 1.0)); draw_circle(pp, s_ico * 0.84, Color(0.10, 0.32, 0.78))
                draw_rect(Rect2(pp - Vector2(s_ico * 0.36, s_ico * 0.36), Vector2(s_ico * 0.72, s_ico * 0.72)), Color(0.98, 0.82, 0.18))
            elif cat == "station":
                draw_circle(pp, s_ico, Color(0.98, 0.95, 0.90)); draw_circle(pp, s_ico * 0.84, Color(0.94, 0.34, 0.10))
                draw_rect(Rect2(pp - Vector2(s_ico * 0.34, s_ico * 0.46), Vector2(s_ico * 0.62, s_ico * 0.92)), Color(0.98, 0.96, 0.92))
            else:
                draw_circle(pp, s_ico, Color(0.98, 0.96, 0.90)); draw_circle(pp, s_ico * 0.84, Color(0.92, 0.64, 0.12))
                draw_rect(Rect2(pp - Vector2(s_ico * 0.48, s_ico * 0.36), Vector2(s_ico * 0.96, s_ico * 0.28)), Color(0.86, 0.20, 0.18))
