extends Node2D

var allies := Array()
var ennemis := Array()

func creer_humain_style(peau : Color, tenue : Color, est_ennemi : bool = false) -> Node2D:
    var corps := Node2D.new()
    var bras := Polygon2D.new()
    bras.polygon = PoolVector2Array([Vector2(-6, -17), Vector2(10, -17), Vector2(10, 17), Vector2(-6, 17)])
    bras.color = peau; corps.add_child(bras)
    var veste := Polygon2D.new()
    veste.polygon = PoolVector2Array([Vector2(-7, -11), Vector2(7, -11), Vector2(8, 11), Vector2(-8, 11)])
    veste.color = tenue; corps.add_child(veste)
    var tete := Polygon2D.new()
    tete.polygon = PoolVector2Array([Vector2(-6, -7), Vector2(8, -7), Vector2(8, 7), Vector2(-6, 7)])
    tete.position = Vector2(4, 0); tete.color = peau; corps.add_child(tete)
    if est_ennemi:
        var band := Polygon2D.new()
        band.polygon = PoolVector2Array([Vector2(1, -7), Vector2(4, -7), Vector2(4, 7), Vector2(1, 7)])
        band.color = Color(0.88, 0.14, 0.14); corps.add_child(band)
    return corps

func creer_humain(coul : Color) -> Node2D:
    if coul.r > 0.7 and coul.g < 0.3:
        return creer_humain_style(Color(0.92, 0.78, 0.66), Color(0.08, 0.08, 0.10), true)
    var peaux := Array([Color(0.30, 0.17, 0.10), Color(0.92, 0.78, 0.66), Color(0.34, 0.19, 0.11)])
    var tenues := Array([Color(0.18, 0.68, 0.36), Color(0.20, 0.52, 0.85), Color(0.92, 0.72, 0.18), Color(0.88, 0.88, 0.92)])
    return creer_humain_style(peaux[randi() % 3], tenues[randi() % 4], false)

func peupler():
    for j in range(45):
        var a = KinematicBody2D.new()
        a.position = Vector2(rand_range(-650, 650), rand_range(-650, 650)) if j < 15 else Vector2(rand_range(-2500, 2800), rand_range(-3500, 2200))
        var peau_c := Color(0.30, 0.17, 0.10) if j % 2 == 0 else Color(0.92, 0.78, 0.66)
        var tenue_c := Color(0.18, 0.68, 0.36) if j % 3 == 0 else (Color(0.22, 0.55, 0.88) if j % 3 == 1 else Color(0.92, 0.74, 0.20))
        a.add_child(creer_humain_style(peau_c, tenue_c, false))
        var col = CollisionShape2D.new(); var sh = CircleShape2D.new(); sh.radius = 15.0; col.shape = sh; a.add_child(col)
        a.set_meta("recrute", false); a.set_meta("cd", 0.0); a.set_meta("dir", Vector2(1, 0))
        add_child(a); allies.append(a)

func _physics_process(_delta):
    for a in allies:
        if is_instance_valid(a) and not a.get_meta("recrute"):
            if a.has_meta("cible_feu"):
                var pf : Vector2 = a.get_meta("cible_feu")
                if a.position.distance_to(pf) > 48.0:
                    a.look_at(pf); a.move_and_slide((pf - a.position).normalized() * 155.0); continue
            var dir = a.get_meta("dir")
            if randf() < 0.02:
                dir = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized(); a.set_meta("dir", dir)
            a.look_at(a.position + dir); a.move_and_slide(dir * 95.0)

func spawn_ennemi(pos_joueur : Vector2, vague : int):
    var en = KinematicBody2D.new(); var ang = rand_range(0, TAU)
    en.position = pos_joueur + Vector2(cos(ang), sin(ang)) * 520.0
    en.add_child(creer_humain_style(Color(0.92, 0.78, 0.66), Color(0.08, 0.08, 0.10), true))
    var col = CollisionShape2D.new(); var sh = CircleShape2D.new(); sh.radius = 15.0; col.shape = sh; en.add_child(col)
    en.set_meta("hp", 75 + vague * 20); en.set_meta("hp_max", 75 + vague * 20); en.set_meta("cd", 0.0); en.set_meta("arme", randf() < 0.55)
    add_child(en); ennemis.append(en)


func _draw():
    for en in ennemis:
        if is_instance_valid(en) and en.has_meta("hp"):
            var hp : float = float(en.get_meta("hp"))
            var hp_max : float = float(en.get_meta("hp_max")) if en.has_meta("hp_max") else 100.0
            var r : float = clamp(hp / max(hp_max, 1.0), 0.0, 1.0)
            var p : Vector2 = en.position + Vector2(-18, -28)
            draw_rect(Rect2(p, Vector2(36, 5)), Color(0.1, 0.1, 0.1, 0.85))
            draw_rect(Rect2(p, Vector2(36.0 * r, 5)), Color(0.92, 0.22, 0.22))
