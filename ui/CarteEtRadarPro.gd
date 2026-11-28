extends Control

var tris_terre := Array()
var est_grande_carte := true

func charger_silhouette():
    tris_terre.clear()
    var f = File.new()
    if f.open("res://triangulation/nc_monde_propre.bin", File.READ) != OK: return
    var nb : int = f.get_32()
    for i in range(nb):
        if f.get_position() + 34 > f.get_len(): break
        var c : int = f.get_8(); f.get_8(); f.get_float(); f.get_float()
        var p0 := Vector2(f.get_float(), f.get_float()); var p1 := Vector2(f.get_float(), f.get_float()); var p2 := Vector2(f.get_float(), f.get_float())
        if c == 1 and i % 8 == 0:
            var t := Array(); t.append(_j2c(p0)); t.append(_j2c(p1)); t.append(_j2c(p2)); tris_terre.append(t)
    f.close()

func _j2c(p : Vector2) -> Vector2:
    var lon : float = 166.4410 + p.x / (1650000.0 * cos(deg2rad(-22.3015)))
    var lat : float = -22.3015 - p.y / 1650000.0
    return Vector2(40.0 + (lon - 163.5) * 130.0, 25.0 + (lat + 19.6) * (-122.0))

func _c2j(m : Vector2) -> Vector2:
    var lon : float = 163.5 + (m.x - 40.0) / 130.0
    var lat : float = -19.6 + (m.y - 25.0) / (-122.0)
    return Vector2((lon - 166.4410) * 1650000.0 * cos(deg2rad(-22.3015)), -(lat + 22.3015) * 1650000.0)

func _gui_input(event):
    if est_grande_carte and event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
        var main = get_tree().get_root().get_node_or_null("Main")
        if main != null and main.get("joueur") != null:
            main.joueur.position = _c2j(event.position)
            get_parent().visible = false
            main.hud.msg_label.text = "🚁 Voyage rapide effectué sur la carte !"

func _draw():
    var main = get_tree().get_root().get_node_or_null("Main")
    var tri := PoolVector2Array(); tri.resize(3)
    var c_ile := PoolColorArray(); c_ile.append(Color(0.24, 0.62, 0.32)); c_ile.append(Color(0.24, 0.62, 0.32)); c_ile.append(Color(0.24, 0.62, 0.32))
    for t in tris_terre:
        var a := Array(t); tri.set(0, a.pop_front()); tri.set(1, a.pop_front()); tri.set(2, a.pop_front())
        draw_primitive(tri, c_ile, PoolVector2Array())
    if main != null and main.get("joueur") != null:
        var pj := _j2c(main.joueur.position)
        draw_circle(pj, 6.0, Color(1.0, 0.15, 0.15)); draw_circle(pj, 2.5, Color.white)
        if main.get("monde") != null:
            draw_circle(_j2c(main.monde.mission_cible), 5.0, Color(1.0, 0.88, 0.12))
