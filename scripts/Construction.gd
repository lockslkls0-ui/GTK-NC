extends Node2D

var mode_build := 0
var constructions := Array()
var _t := 0.0

func _ready():
    z_index = 12

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
        var sc : int = event.scancode
        var uc : int = event.unicode
        if sc == KEY_1 or sc == KEY_KP_1 or sc == KEY_AMPERSAND or uc == 49 or uc == 38:
            mode_build = 0 if mode_build == 1 else 1
            m.hud.msg_label.text = "🪵 Mode Construction : Palissade (10 Bois) — Clic droit pour poser" if mode_build == 1 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
        elif sc == KEY_2 or sc == KEY_KP_2 or sc == KEY_EACUTE or uc == 50 or uc == 233:
            mode_build = 0 if mode_build == 2 else 2
            m.hud.msg_label.text = "🛖 Mode Construction : Faré / Cabane (25 Bois) — Clic droit pour poser" if mode_build == 2 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
        elif sc == KEY_3 or sc == KEY_KP_3 or sc == KEY_QUOTEDBL or uc == 51 or uc == 34:
            mode_build = 0 if mode_build == 3 else 3
            m.hud.msg_label.text = "🗼 Mode Construction : Tourelle de garde (40 Bois) — Clic droit pour poser" if mode_build == 3 else "Construction désactivée"
            get_tree().set_input_as_handled(); update()
    elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_RIGHT and mode_build > 0 and not j.en_vehicule:
        get_tree().set_input_as_handled()
        var cout := 10 if mode_build == 1 else (25 if mode_build == 2 else 40)
        if m.bois < cout:
            m.hud.msg_label.text = "❌ Pas assez de bois (" + str(m.bois) + "/" + str(cout) + ") — Coupe des arbres avec [C] !"
            return
        m.bois -= cout
        var pos := _cible(j)
        constructions.append({"type": mode_build, "pos": pos, "cd": 0.0})
        var bat := StaticBody2D.new(); bat.position = pos
        var col := CollisionShape2D.new(); var sh := RectangleShape2D.new()
        sh.extents = Vector2(34, 9) if mode_build == 1 else (Vector2(42, 42) if mode_build == 2 else Vector2(20, 20))
        col.shape = sh; bat.add_child(col); add_child(bat)
        if m.get("audio") != null: m.audio.p_ok.play()
        m.hud.msg_label.text = "✅ Construction posée au premier plan ! Bois restant : " + str(m.bois)
        update()

func _process(delta):
    var m = get_parent()
    for c_item in constructions:
        if c_item["type"] == 3 and m != null and m.get("pop") != null:
            c_item["cd"] -= delta
            if c_item["cd"] <= 0.0:
                var p_t : Vector2 = c_item["pos"]
                for en in m.pop.ennemis:
                    if is_instance_valid(en) and en.position.distance_squared_to(p_t) < 202500.0:
                        c_item["cd"] = 0.75
                        m.armes.tirer_projectile(p_t, (en.position - p_t).normalized(), 820.0, 35.0, true, Color(1.0, 0.85, 0.2))
                        break
    if mode_build == 0: return
    _t += delta
    if _t >= 0.08:
        _t = 0.0; update()

func _draw():
    for c_item in constructions:
        var p : Vector2 = c_item["pos"]
        var tp : int = c_item["type"]
        if tp == 1:
            draw_rect(Rect2(p - Vector2(34, 9), Vector2(68, 18)), Color(0.58, 0.36, 0.14))
            draw_rect(Rect2(p - Vector2(34, 9), Vector2(68, 18)), Color(0.24, 0.14, 0.05), false, 2.5)
        elif tp == 2:
            draw_rect(Rect2(p - Vector2(42, 42), Vector2(84, 84)), Color(0.70, 0.50, 0.22))
            draw_rect(Rect2(p - Vector2(32, 32), Vector2(64, 64)), Color(0.84, 0.64, 0.28))
            draw_rect(Rect2(p - Vector2(42, 42), Vector2(84, 84)), Color(0.28, 0.18, 0.06), false, 3.0)
        elif tp == 3:
            draw_circle(p, 22.0, Color(0.32, 0.38, 0.46))
            draw_circle(p, 11.0, Color(0.92, 0.30, 0.22))
    var m = get_parent()
    if m == null or m.get("joueur") == null or mode_build == 0: return
    var j = m.joueur
    if j.en_vehicule: return
    var pos := _cible(j)
    var cout := 10 if mode_build == 1 else (25 if mode_build == 2 else 40)
    var c := Color(0.25, 0.92, 0.45, 0.5) if m.bois >= cout else Color(0.95, 0.25, 0.25, 0.5)
    if mode_build == 1: draw_rect(Rect2(pos - Vector2(34, 9), Vector2(68, 18)), c)
    elif mode_build == 2: draw_rect(Rect2(pos - Vector2(42, 42), Vector2(84, 84)), c)
    elif mode_build == 3: draw_circle(pos, 22.0, c)
