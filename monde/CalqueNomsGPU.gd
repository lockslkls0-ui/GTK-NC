extends CanvasLayer

var lieux := Array()
var pois := Array()
var labels := Array()

func initialiser(liste_pois : Array):
    layer = 5
    pois = liste_pois
    var lat0 := -22.3015; var lon0 := 166.4410; var ech := 1650000.0
    var f = File.new()
    if f.open("res://nc_toponymes.json", File.READ) == OK:
        var j = JSON.parse(f.get_as_text()); f.close()
        if j.error == OK and typeof(j.result) == TYPE_DICTIONARY:
            for t in j.result.get("toponymes", Array()):
                var pt := Vector2((float(t["lon"]) - lon0) * ech * cos(deg2rad(lat0)), -(float(t["lat"]) - lat0) * ech)
                lieux.append({"nom": str(t["nom"]), "cat": str(t.get("cat", "lieu")), "pos": pt})
    for _i in range(65):
        var lb := Label.new(); lb.visible = false
        lb.add_color_override("font_color_shadow", Color(0.02, 0.04, 0.06, 0.95))
        lb.add_constant_override("shadow_offset_x", 2); lb.add_constant_override("shadow_offset_y", 2)
        add_child(lb); labels.append(lb)

func _process(_delta):
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null or j.cam == null: return
    var z : float = j.cam.zoom.x
    var vt := get_viewport().canvas_transform
    var sz := get_viewport().size
    var idx := 0; var max_l := labels.size()
    if z >= 1.25:
        for l in lieux:
            if idx >= max_l: break
            if l["cat"] == "commune":
                var pe : Vector2 = vt.xform(l["pos"])
                if pe.x > -100 and pe.x < sz.x + 100 and pe.y > -40 and pe.y < sz.y + 40:
                    var lb : Label = labels[idx]; lb.text = "📍 " + l["nom"].to_upper(); lb.rect_position = pe - Vector2(36, 10)
                    lb.add_color_override("font_color", Color(1.0, 0.90, 0.25)); lb.visible = true; idx += 1
    if z < 5.5:
        for l in lieux:
            if idx >= max_l: break
            if l["cat"] != "commune":
                var pe : Vector2 = vt.xform(l["pos"])
                if pe.x > 0 and pe.x < sz.x and pe.y > 0 and pe.y < sz.y:
                    var lb : Label = labels[idx]; lb.text = l["nom"]; lb.rect_position = pe + Vector2(6, -8)
                    lb.add_color_override("font_color", Color(0.98, 0.96, 0.88)); lb.visible = true; idx += 1
        if z < 2.8:
            for po in pois:
                if idx >= max_l: break
                var a := Array(po); var pp : Vector2 = a.pop_front(); var cat : String = a.pop_front(); var nom_p : String = a.pop_front()
                var pe : Vector2 = vt.xform(pp)
                if pe.x > 0 and pe.x < sz.x and pe.y > 0 and pe.y < sz.y and nom_p != "":
                    var lb : Label = labels[idx]; lb.text = nom_p; lb.rect_position = pe + Vector2(14, -8)
                    lb.add_color_override("font_color", Color(1.0, 0.45, 0.45) if cat == "hopital" else (Color(0.45, 0.78, 1.0) if cat == "police" else Color(1.0, 0.82, 0.32)))
                    lb.visible = true; idx += 1
    for k in range(idx, max_l): labels[k].visible = false
