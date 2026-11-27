extends Node2D

var vehicules := Array()
var remorques_libres := Array()
var arbres_locaux := Array()
var segs_noumea := Array()
var remorque_joueur = null
var _acc := 0.0
var _init_fait := false

func initialiser(_routes_src : Array):
    var f = File.new()
    if f.open("res://triangulation/nc_reseau_arbres.bin", File.READ) != OK: return
    var nr : int = f.get_32(); var nb : int = f.get_32(); var nrv : int = f.get_32(); var na : int = f.get_32()
    for _ir in range(nr):
        if f.get_position() + 20 > f.get_len(): break
        var pa := Vector2(f.get_float(), f.get_float()); var pb := Vector2(f.get_float(), f.get_float()); f.get_float()
        if pa.distance_squared_to(pb) > 900.0 and segs_noumea.size() < 600:
            var s := Array(); s.append(pa); s.append(pb); segs_noumea.append(s)
    f.seek(16 + nr * 20 + nb * 16 + nrv * 20)
    for ia in range(na):
        if f.get_position() + 12 > f.get_len(): break
        var ap := Vector2(f.get_float(), f.get_float()); var ar : float = f.get_float()
        if ia % 12 == 0 and arbres_locaux.size() < 4000:
            arbres_locaux.append({"pos": ap, "r": clamp(ar, 9.0, 18.0), "pv": 3})
    f.close()

func _placer_autour_joueur(pj : Vector2):
    _init_fait = true
    remorques_libres.append({"avec_bateau": true, "pos": pj + Vector2(110, 40), "ang": 0.0})
    remorques_libres.append({"avec_bateau": false, "pos": pj + Vector2(-115, 65), "ang": 0.3})
    var cols := Array()
    cols.append(Color(0.95, 0.96, 0.98)); cols.append(Color(0.86, 0.22, 0.20)); cols.append(Color(0.18, 0.46, 0.82))
    for k in range(18):
        var off := Vector2(cos(float(k) * 0.35), sin(float(k) * 0.35)) * (180.0 + float(k % 4) * 140.0)
        var pa := pj + off
        var pb := pa + Vector2(-off.y, off.x).normalized() * 450.0
        var rem = null
        if k % 3 == 0: rem = {"avec_bateau": (k % 6 == 0), "pos": pa, "ang": (pb - pa).angle()}
        vehicules.append({"pa": pa, "pb": pb, "t": 0.1, "vit": 120.0, "col": cols[k % 3], "remorque": rem})
    for a in range(28):
        var ang_a := float(a) * 0.224
        var d_a := 130.0 + float(a % 5) * 95.0
        arbres_locaux.append({"pos": pj + Vector2(cos(ang_a), sin(ang_a)) * d_a, "r": 14.0, "pv": 3})

func _unhandled_input(event):
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null: return
    if event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_G and j.en_vehicule:
        get_tree().set_input_as_handled()
        if remorque_joueur != null:
            remorques_libres.append(remorque_joueur); remorque_joueur = null
            if m.get("hud") != null: m.hud.msg_label.text = "⚓ Remorque dételée !"
        else:
            for i in range(remorques_libres.size()):
                if remorques_libres[i]["pos"].distance_to(j.position) < 140.0:
                    remorque_joueur = remorques_libres[i]; remorques_libres.remove(i)
                    if m.get("hud") != null: m.hud.msg_label.text = "🛻 Remorque attelée ([G] en véhicule pour dételer) !"
                    return
            for v in vehicules:
                if v["remorque"] != null and v["remorque"]["pos"].distance_to(j.position) < 140.0:
                    remorque_joueur = v["remorque"]; v["remorque"] = null
                    if m.get("hud") != null: m.hud.msg_label.text = "🛻 Remorque décrochée et attelée à ton véhicule !"
                    return
    elif event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_E:
        for idx in range(arbres_locaux.size() - 1, -1, -1):
            if arbres_locaux[idx]["pos"].distance_to(j.position) < 75.0:
                arbres_locaux[idx]["pv"] -= 1
                j.bois += 2
                if m.get("hud") != null: m.hud.msg_label.text = "🪓 +2 Bois coupé ! (Total : " + str(j.bois) + ")"
                if arbres_locaux[idx]["pv"] <= 0: arbres_locaux.remove(idx)
                update(); return

func _process(delta):
    _acc += delta
    if _acc < 0.05: return
    var dt := _acc; _acc = 0.0
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null: return
    if not _init_fait: _placer_autour_joueur(j.position)
    for v in vehicules:
        var dist : float = max(v["pa"].distance_to(v["pb"]), 10.0)
        v["t"] += (v["vit"] * dt / dist)
        if v["t"] >= 1.0:
            var tmp : Vector2 = v["pa"]; v["pa"] = v["pb"]; v["pb"] = tmp; v["t"] = 0.0
        if v["remorque"] != null:
            var pos_v : Vector2 = v["pa"].linear_interpolate(v["pb"], v["t"])
            var ang_v : float = (v["pb"] - v["pa"]).angle()
            v["remorque"]["pos"] = pos_v - Vector2(cos(ang_v), sin(ang_v)) * 42.0
            v["remorque"]["ang"] = ang_v
    if remorque_joueur != null:
        var dir_j : Vector2 = (j.position - remorque_joueur["pos"])
        if dir_j.length() > 44.0:
            remorque_joueur["ang"] = dir_j.angle()
            remorque_joueur["pos"] = j.position - dir_j.normalized() * 44.0
    update()

func _dessiner_remorque(r : Dictionary):
    draw_set_transform(r["pos"], r["ang"], Vector2.ONE)
    draw_line(Vector2(16, 0), Vector2(26, 0), Color(0.55, 0.58, 0.62), 3.0)
    draw_rect(Rect2(-18, -9, 34, 18), Color(0.32, 0.35, 0.40))
    draw_rect(Rect2(-4, -11, 8, 22), Color(0.10, 0.10, 0.12))
    if r["avec_bateau"]:
        draw_rect(Rect2(-15, -7, 30, 14), Color(0.96, 0.97, 1.0))
        draw_rect(Rect2(-4, -5, 12, 10), Color(0.18, 0.52, 0.86))

func _draw():
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null: return
    var pj : Vector2 = j.position
    for ar in arbres_locaux:
        if ar["pos"].distance_squared_to(pj) < 3600000.0:
            draw_circle(ar["pos"] + Vector2(3, 4), ar["r"], Color(0.05, 0.12, 0.05, 0.45))
            draw_circle(ar["pos"], ar["r"], Color(0.14, 0.48, 0.18))
            draw_circle(ar["pos"] - Vector2(3, 3), ar["r"] * 0.55, Color(0.24, 0.64, 0.26))
    for v in vehicules:
        var pos : Vector2 = v["pa"].linear_interpolate(v["pb"], v["t"])
        if pos.distance_squared_to(pj) < 6400000.0:
            var ang : float = (v["pb"] - v["pa"]).angle()
            draw_set_transform(pos, ang, Vector2.ONE)
            draw_rect(Rect2(-18, -9, 36, 18), v["col"])
            draw_rect(Rect2(-7, -7, 15, 14), Color(0.12, 0.16, 0.22))
            if v["remorque"] != null: _dessiner_remorque(v["remorque"])
    for rl in remorques_libres:
        if rl["pos"].distance_squared_to(pj) < 6400000.0: _dessiner_remorque(rl)
    if remorque_joueur != null: _dessiner_remorque(remorque_joueur)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
