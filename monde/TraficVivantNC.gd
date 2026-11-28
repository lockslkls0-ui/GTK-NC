extends Node2D

var arbres_locaux := Array()
var secteurs_faits := Dictionary()
var _cd_maj := 0.0

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
        if ia % 4 == 0 and arbres_locaux.size() < 4500:
            arbres_locaux.append({"pos": ap, "r": clamp(ar, 11.0, 20.0), "pv": 3})
    f.close()

func _peupler_secteur(m, pj : Vector2):
    var gx := int(floor(pj.x / 2000.0)); var gy := int(floor(pj.y / 2000.0))
    var ajout := false
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            var cle := str(gx + dx) + "_" + str(gy + dy)
            if not secteurs_faits.has(cle):
                secteurs_faits[cle] = true; ajout = true
                var c := Vector2(float(gx + dx) * 2000.0 + 1000.0, float(gy + dy) * 2000.0 + 1000.0)
                for a in range(18):
                    var ang := float(a) * 0.349 + float(dx + dy)
                    var d := 140.0 + float((a * 73) % 820)
                    arbres_locaux.append({"pos": c + Vector2(cos(ang), sin(ang)) * d, "r": 13.0 + float(a % 6), "pv": 3})
                if m != null:
                    var caisse := ColorRect.new()
                    caisse.rect_size = Vector2(28, 22); caisse.color = Color(0.88, 0.62, 0.18)
                    caisse.rect_position = c + Vector2(rand_range(-450, 450), rand_range(-450, 450))
                    caisse.set_meta("ouvert", false); m.add_child(caisse); m.caisses.append(caisse)
    if ajout: update()

func _couper_arbre(m, j) -> bool:
    for idx in range(arbres_locaux.size() - 1, -1, -1):
        if arbres_locaux[idx]["pos"].distance_to(j.position) < 90.0:
            arbres_locaux[idx]["pv"] -= 1; m.bois += 3
            if m.get("hud") != null: m.hud.msg_label.text = "🪓 +3 Bois coupé ! (Total : " + str(m.bois) + ")"
            if arbres_locaux[idx]["pv"] <= 0: arbres_locaux.remove(idx)
            update(); return true
    return false

func _ready():
    z_index = 4

func _input(event):
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null or j.en_vehicule: return
    if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
        if _couper_arbre(m, j):
            m.gagner_xp(12.0, "Récolte de bois")
            if m.get("audio") != null: m.audio.p_ok.play()
            get_tree().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_C:
        if _couper_arbre(m, j):
            m.gagner_xp(12.0, "Récolte de bois")
            if m.get("audio") != null: m.audio.p_ok.play()
            get_tree().set_input_as_handled()

func _process(delta):
    _cd_maj += delta
    if _cd_maj < 0.25: return
    _cd_maj = 0.0
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j != null:
        _peupler_secteur(m, j.position)

func _draw():
    var m = get_parent().get_parent()
    var j = m.get("joueur") if m != null else null
    if j == null: return
    var pj : Vector2 = j.position
    var r_vue : float = 2800.0 * max(j.cam.zoom.x, 1.0)
    var r2_max : float = r_vue * r_vue
    for ar in arbres_locaux:
        if ar["pos"].distance_squared_to(pj) < r2_max:
            draw_circle(ar["pos"] + Vector2(3, 4), ar["r"], Color(0.05, 0.12, 0.05, 0.45))
            draw_circle(ar["pos"], ar["r"], Color(0.14, 0.48, 0.18))
            draw_circle(ar["pos"] - Vector2(3, 3), ar["r"] * 0.55, Color(0.24, 0.64, 0.26))
