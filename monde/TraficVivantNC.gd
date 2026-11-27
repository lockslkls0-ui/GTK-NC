extends Node2D

var arbres_locaux := Array()
var _init_fait := false

func initialiser(_routes_src : Array):
    OS.low_processor_usage_mode = true
    Engine.target_fps = 24
    var f = File.new()
    if f.open("res://triangulation/nc_reseau_arbres.bin", File.READ) != OK: return
    var nr : int = f.get_32(); var nb : int = f.get_32(); var nrv : int = f.get_32(); var na : int = f.get_32()
    f.seek(16 + nr * 20 + nb * 16 + nrv * 20)
    for ia in range(na):
        if f.get_position() + 12 > f.get_len(): break
        var ap := Vector2(f.get_float(), f.get_float()); var ar : float = f.get_float()
        if ia % 15 == 0 and arbres_locaux.size() < 3500:
            arbres_locaux.append({"pos": ap, "r": clamp(ar, 10.0, 18.0), "pv": 3})
    f.close()

func _placer_arbres_depart(pj : Vector2):
    _init_fait = true
    for a in range(24):
        var ang_a := float(a) * 0.2618; var d_a := 130.0 + float(a % 4) * 95.0
        arbres_locaux.append({"pos": pj + Vector2(cos(ang_a), sin(ang_a)) * d_a, "r": 14.0, "pv": 3})

func _couper_arbre(m, j) -> bool:
    for idx in range(arbres_locaux.size() - 1, -1, -1):
        if arbres_locaux[idx]["pos"].distance_to(j.position) < 85.0:
            arbres_locaux[idx]["pv"] -= 1; m.bois += 2
            if m.get("hud") != null: m.hud.msg_label.text = "🪓 +2 Bois coupé ! (Total : " + str(m.bois) + ")"
            if arbres_locaux[idx]["pv"] <= 0: arbres_locaux.remove(idx)
            update(); return true
    return false

func _unhandled_input(event):
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null or j.en_vehicule: return
    if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
        if _couper_arbre(m, j): get_tree().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_C:
        if _couper_arbre(m, j): get_tree().set_input_as_handled()

func _process(_delta):
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j != null and not _init_fait:
        _placer_arbres_depart(j.position); update()

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
