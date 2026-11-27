extends Node2D

var mode_actif := 0
var constructions := Array()
var _t := 0.0

func _cible(j) -> Vector2:
    var p : Vector2 = get_global_mouse_position()
    if p.distance_to(j.position) > 220.0:
        p = j.position + (p - j.position).normalized() * 220.0
    return p

func _input(event):
    var m = get_parent()
    if m == null or m.get("joueur") == null: return
    var j = m.joueur
    if event is InputEventKey and event.pressed and not event.echo:
        if (event.scancode == KEY_1 or event.scancode == KEY_KP_1 or event.scancode == KEY_AMPERSAND or event.unicode == 49 or event.unicode == 38):
            mode_actif = 0 if mode_actif == 1 else 1
            m.hud.msg_label.text = "🪵 Mode Construction : Palissade (10 Bois) — Clic droit pour poser" if mode_actif == 1 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
        elif (event.scancode == KEY_2 or event.scancode == KEY_KP_2 or event.scancode == KEY_EACUTE or event.unicode == 50 or event.unicode == 233):
            mode_actif = 0 if mode_actif == 2 else 2
            m.hud.msg_label.text = "🛖 Mode Construction : Faré / Cabane (25 Bois) — Clic droit pour poser" if mode_actif == 2 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
        elif (event.scancode == KEY_3 or event.scancode == KEY_KP_3 or event.scancode == KEY_QUOTEDBL or event.unicode == 51 or event.unicode == 34):
            mode_actif = 0 if mode_actif == 3 else 3
            m.hud.msg_label.text = "🗼 Mode Construction : Tourelle (40 Bois) — Clic droit pour poser" if mode_actif == 3 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
    elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT and mode_actif > 0 and not j.en_vehicule:
        get_tree().set_input_as_handled()
        var cout := 10 if mode_actif == 1 else (25 if mode_actif == 2 else 40)
        if m.bois < cout:
            m.hud.msg_label.text = "❌ Pas assez de bois (" + str(m.bois) + "/" + str(cout) + ") — Coupe des arbres avec [C] !"
            return
        m.bois -= cout
        var pos := _cible(j)
        constructions.append({"type": mode_actif, "pos": pos})
        var bat := StaticBody2D.new(); bat.position = pos
        var col := CollisionShape2D.new(); var sh := RectangleShape2D.new()
        sh.extents = Vector2(32, 8) if mode_actif == 1 else (Vector2(40, 40) if mode_actif == 2 else Vector2(18, 18))
        col.shape = sh; bat.add_child(col); m.add_child(bat)
        if m.get("audio") != null: m.audio.p_ok.play()
        m.hud.msg_label.text = "✅ Construction posée ! Bois restant : " + str(m.bois)
        update()

func _process(delta):
    if mode_actif == 0: return
    _t += delta
    if _t < 0.08: return
    _t = 0.0
    update()

func _draw():
    for c_item in constructions:
        var p : Vector2 = c_item["pos"]
        var tp : int = c_item["type"]
        if tp == 1:
            draw_rect(Rect2(p - Vector2(32, 8), Vector2(64, 16)), Color(0.55, 0.34, 0.14))
            draw_rect(Rect2(p - Vector2(32, 8), Vector2(64, 16)), Color(0.28, 0.16, 0.06), false, 2.0)
        elif tp == 2:
            draw_rect(Rect2(p - Vector2(40, 40), Vector2(80, 80)), Color(0.68, 0.48, 0.22))
            draw_rect(Rect2(p - Vector2(32, 32), Vector2(64, 64)), Color(0.82, 0.62, 0.28))
            draw_rect(Rect2(p - Vector2(40, 40), Vector2(80, 80)), Color(0.32, 0.20, 0.08), false, 2.5)
        elif tp == 3:
            draw_circle(p, 20.0, Color(0.35, 0.42, 0.50))
            draw_circle(p, 10.0, Color(0.88, 0.28, 0.22))
    var m = get_parent()
    if m == null or m.get("joueur") == null or mode_actif == 0: return
    var j = m.joueur
    if j.en_vehicule: return
    var pos := _cible(j)
    var cout := 10 if mode_actif == 1 else (25 if mode_actif == 2 else 40)
    var c := Color(0.25, 0.92, 0.45, 0.45) if m.bois >= cout else Color(0.95, 0.25, 0.25, 0.45)
    if mode_actif == 1: draw_rect(Rect2(pos - Vector2(32, 8), Vector2(64, 16)), c)
    elif mode_actif == 2: draw_rect(Rect2(pos - Vector2(40, 40), Vector2(80, 80)), c)
    elif mode_actif == 3: draw_circle(pos, 20.0, c)
