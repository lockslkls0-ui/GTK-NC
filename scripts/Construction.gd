extends Node2D

var mode_build := 0
var vertical := false
var constructions := Array()
var dernier_abri := Vector2.ZERO
var a_un_abri := false
var _t := 0.0

func _ready():
    z_index = 12

func poser_structure(_p, _t, _b):
    return 0

func _cible(j) -> Vector2:
    var p : Vector2 = get_global_mouse_position()
    if p.distance_to(j.position) > 220.0:
        p = j.position + (p - j.position).normalized() * 220.0
    return p

func _index_vise(j) -> int:
    var pm : Vector2 = get_global_mouse_position()
    var best := -1; var d_best := 125.0
    for i in range(constructions.size()):
        var p : Vector2 = constructions[i]["pos"]
        if p.distance_to(j.position) < 155.0:
            var dm : float = p.distance_to(pm)
            if dm < d_best:
                d_best = dm; best = i
    return best

func _input(event):
    var m = get_parent()
    if m == null or m.get("joueur") == null: return
    var j = m.joueur
    if event is InputEventKey and event.pressed and not event.echo:
        var sc : int = event.scancode; var uc : int = event.unicode
        if sc == KEY_1 or sc == KEY_KP_1 or sc == KEY_AMPERSAND or uc == 49 or uc == 38:
            mode_build = 0 if mode_build == 1 else 1
            m.hud.msg_label.text = "🪵 Palissade (10 Bois) — [R] pivoter | [E] ouvrir | [Suppr] retirer" if mode_build == 1 else "Construction off"
            get_tree().set_input_as_handled(); update()
        elif sc == KEY_2 or sc == KEY_KP_2 or sc == KEY_EACUTE or uc == 50 or uc == 233:
            mode_build = 0 if mode_build == 2 else 2
            m.hud.msg_label.text = "🛖 Cabane (25 Bois) = Point de Sauvegarde — Clic droit poser" if mode_build == 2 else "Construction off"
            get_tree().set_input_as_handled(); update()
        elif sc == KEY_3 or sc == KEY_KP_3 or sc == KEY_QUOTEDBL or uc == 51 or uc == 34:
            mode_build = 0 if mode_build == 3 else 3
            m.hud.msg_label.text = "🗼 Tourelle Auto (40 Bois) — Clic droit poser" if mode_build == 3 else "Construction off"
            get_tree().set_input_as_handled(); update()
        elif sc == KEY_R:
            get_tree().set_input_as_handled()
            if mode_build == 1:
                vertical = not vertical; update()
            elif m.get("armes") != null:
                m.hud.msg_label.text = m.armes.recharger()
                if m.get("audio") != null: m.audio.p_ok.play()
        elif (sc == KEY_F9 or sc == KEY_F5) and m.hud.get("save_panel") != null:
            m.hud.save_panel.rafraichir(); m.hud.save_panel.visible = not m.hud.save_panel.visible; get_tree().set_input_as_handled()
        elif sc == KEY_X and m.get("eco") != null:
            m.eco.z_index = 20; m.hud.msg_label.text = m.eco.poser_explosif(j.position); get_tree().set_input_as_handled()
        elif sc == KEY_H and m.hud.get("respawn_panel") != null:
            m.hud.respawn_panel.visible = not m.hud.respawn_panel.visible; get_tree().set_input_as_handled()
        elif sc == KEY_E and not j.en_vehicule and _index_vise(j) != -1:
            var iv := _index_vise(j)
            if iv != -1 and constructions[iv]["type"] == 1:
                constructions[iv]["ouvert"] = not constructions[iv]["ouvert"]
                constructions[iv]["col"].disabled = constructions[iv]["ouvert"]
                m.hud.msg_label.text = "🚪 Portail OUVERT !" if constructions[iv]["ouvert"] else "🔒 Portail FERMÉ !"
                get_tree().set_input_as_handled(); update(); return
        elif sc == KEY_DELETE or sc == KEY_BACKSPACE:
            var iv2 := _index_vise(j)
            if iv2 != -1:
                var rb := 5 if constructions[iv2]["type"] == 1 else (12 if constructions[iv2]["type"] == 2 else 20)
                m.bois += rb
                if is_instance_valid(constructions[iv2]["bat"]): constructions[iv2]["bat"].queue_free()
                constructions.remove(iv2)
                m.hud.msg_label.text = "♻️ Retiré (+" + str(rb) + " Bois)"
                get_tree().set_input_as_handled(); update(); return
    elif event is InputEventMouseButton and event.pressed and mode_build > 0 and not j.en_vehicule:
        if (event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN) and mode_build == 1:
            vertical = not vertical; get_tree().set_input_as_handled(); update()
        elif event.button_index == BUTTON_RIGHT:
            get_tree().set_input_as_handled()
            var cout := 10 if mode_build == 1 else (25 if mode_build == 2 else 40)
            if m.bois < cout:
                m.hud.msg_label.text = "❌ Pas assez de bois (" + str(m.bois) + "/" + str(cout) + ")"; return
            m.bois -= cout
            var pos := _cible(j)
            var bat := StaticBody2D.new(); bat.position = pos; bat.collision_layer = 2; bat.collision_mask = 1
            var col := CollisionShape2D.new(); var sh := RectangleShape2D.new()
            if mode_build == 2:
                sh.extents = Vector2(44, 7); col.position = Vector2(0, -37); col.shape = sh; bat.add_child(col)
                var c_g := CollisionShape2D.new(); var s_g := RectangleShape2D.new(); s_g.extents = Vector2(7, 44); c_g.position = Vector2(-37, 0); c_g.shape = s_g; bat.add_child(c_g)
                var c_d := CollisionShape2D.new(); var s_d := RectangleShape2D.new(); s_d.extents = Vector2(7, 44); c_d.position = Vector2(37, 0); c_d.shape = s_d; bat.add_child(c_d)
                dernier_abri = pos; a_un_abri = true
            else:
                var ext_p := Vector2(9, 34) if vertical else Vector2(34, 9)
                sh.extents = ext_p if mode_build == 1 else Vector2(22, 22)
                col.shape = sh; bat.add_child(col)
            add_child(bat)
            var pv_i := 1200.0 if mode_build == 1 else (2500.0 if mode_build == 2 else 1800.0)
            constructions.append({"type": mode_build, "pos": pos, "vert": vertical, "ouvert": false, "pv": pv_i, "pv_max": pv_i, "bat": bat, "col": col, "cd": 0.0, "ang": 0.0})
            if m.get("audio") != null: m.audio.p_ok.play()
            if mode_build == 2 and m.hud.get("save_panel") != null: m.hud.save_panel._on_save()
            m.hud.msg_label.text = "🛖 Cabane posée + Sauvegarde automatique effectuée !" if mode_build == 2 else "✅ Construction posée !"
            update()

func _process(delta):
    var m = get_parent()
    if m == null or m.get("pop") == null: return
    for idx in range(constructions.size() - 1, -1, -1):
        var c_item = constructions[idx]; var p_t : Vector2 = c_item["pos"]
        if c_item["type"] == 3:
            c_item["cd"] -= delta
            var cible_en = null; var d_min := 490000.0
            for en in m.pop.ennemis:
                if is_instance_valid(en):
                    var d2 : float = en.position.distance_squared_to(p_t)
                    if d2 < d_min: d_min = d2; cible_en = en
            if cible_en != null:
                var v_en : Vector2 = cible_en.get_meta("dir") * 110.0 if cible_en.has_meta("dir") else Vector2.ZERO
                var t_vol : float = cible_en.position.distance_to(p_t) / 1050.0
                var dir_t : Vector2 = ((cible_en.position + v_en * t_vol) - p_t).normalized(); c_item["ang"] = dir_t.angle()
                if c_item["cd"] <= 0.0:
                    c_item["cd"] = 0.28; m.armes.tirer(p_t + dir_t * 32.0, dir_t, true, 65.0)
                update()
        for en2 in m.pop.ennemis:
            if is_instance_valid(en2) and en2.position.distance_squared_to(p_t) < 4200.0: c_item["pv"] -= 12.0 * delta
        if c_item["pv"] <= 0.0:
            if is_instance_valid(c_item["bat"]): c_item["bat"].queue_free()
            constructions.remove(idx); update()
    _t += delta
    if _t >= 0.12: _t = 0.0; update()

func _draw():
    var m = get_parent()
    var j = m.get("joueur") if m != null else null
    var iv := _index_vise(j) if j != null else -1
    for i in range(constructions.size()):
        var c_item = constructions[i]; var p : Vector2 = c_item["pos"]; var tp : int = c_item["type"]
        if tp == 1:
            if c_item.get("ouvert", false):
                var r_o := Rect2(p - Vector2(9, 34), Vector2(18, 14)) if c_item.get("vert", false) else Rect2(p - Vector2(34, 9), Vector2(14, 18))
                var r_o2 := Rect2(p + Vector2(-9, 20), Vector2(18, 14)) if c_item.get("vert", false) else Rect2(p + Vector2(20, -9), Vector2(14, 18))
                draw_rect(r_o, Color(0.58, 0.36, 0.14)); draw_rect(r_o2, Color(0.58, 0.36, 0.14))
            else:
                var r_p := Rect2(p - Vector2(9, 34), Vector2(18, 68)) if c_item.get("vert", false) else Rect2(p - Vector2(34, 9), Vector2(68, 18))
                draw_rect(r_p, Color(0.58, 0.36, 0.14))
                draw_rect(r_p, Color(1.0, 0.95, 0.65) if i == iv else Color(0.24, 0.14, 0.05), false, 3.0 if i == iv else 2.0)
        elif tp == 2:
            draw_rect(Rect2(p - Vector2(44, 44), Vector2(88, 88)), Color(0.55, 0.38, 0.18, 0.72))
            draw_rect(Rect2(p - Vector2(44, 44), Vector2(88, 12)), Color(0.38, 0.22, 0.08))
            draw_rect(Rect2(p - Vector2(44, 44), Vector2(12, 88)), Color(0.38, 0.22, 0.08))
            draw_rect(Rect2(p + Vector2(32, -44), Vector2(12, 88)), Color(0.38, 0.22, 0.08))
            draw_rect(Rect2(p + Vector2(-18, 34), Vector2(36, 10)), Color(0.25, 0.85, 0.45, 0.65))
            draw_circle(p + Vector2(0, -52), 6.0, Color(0.20, 0.95, 0.45))
        elif tp == 3:
            draw_circle(p, 24.0, Color(0.24, 0.28, 0.34)); draw_circle(p, 15.0, Color(0.38, 0.44, 0.52))
            var a_t : float = c_item.get("ang", 0.0); var dir := Vector2(cos(a_t), sin(a_t)); var perp := Vector2(-dir.y, dir.x) * 4.5
            draw_line(p + perp, p + perp + dir * 34.0, Color(0.15, 0.17, 0.20), 5.0)
            draw_line(p - perp, p - perp + dir * 34.0, Color(0.15, 0.17, 0.20), 5.0)
            draw_circle(p, 7.0, Color(0.95, 0.28, 0.22))
    if j == null or mode_build == 0 or j.en_vehicule: return
    var pos := _cible(j); var cout := 10 if mode_build == 1 else (25 if mode_build == 2 else 40)
    var c := Color(0.25, 0.92, 0.45, 0.5) if m.bois >= cout else Color(0.95, 0.25, 0.25, 0.5)
    if mode_build == 1:
        var r_ap := Rect2(pos - Vector2(9, 34), Vector2(18, 68)) if vertical else Rect2(pos - Vector2(34, 9), Vector2(68, 18))
        draw_rect(r_ap, c)
    elif mode_build == 2: draw_rect(Rect2(pos - Vector2(44, 44), Vector2(88, 88)), c)
    elif mode_build == 3: draw_circle(pos, 24.0, c)
