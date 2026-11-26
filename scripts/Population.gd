extends Node2D
func charger_tex(chemin : String) -> ImageTexture:
    var img = Image.new()
    if img.load(chemin) != OK: return null
    var tex = ImageTexture.new(); tex.create_from_image(img); return tex

var allies := []
var ennemis := []

func creer_humain(coul : Color) -> Node2D:
    var corps = Node2D.new()
    var ep = Polygon2D.new()
    ep.polygon = PoolVector2Array([Vector2(-10,-17), Vector2(10,-17), Vector2(11,17), Vector2(-10,17)])
    ep.color = coul
    corps.add_child(ep)
    var tete = Polygon2D.new()
    tete.polygon = PoolVector2Array([Vector2(-7,-8), Vector2(9,-8), Vector2(9,8), Vector2(-7,8)])
    tete.color = Color(0.92, 0.76, 0.62)
    corps.add_child(tete)
    var f_h = "ennemi.png" if coul.r > 0.7 else "allie.png"
    var th = charger_tex("res://assets/" + f_h)
    if th != null:
        ep.visible = false; tete.visible = false; var sh = Sprite.new(); sh.texture = th; corps.add_child(sh)
    return corps

func peupler():
    for j in range(45):
        var a = KinematicBody2D.new()
        a.position = Vector2(rand_range(-650, 650), rand_range(-650, 650)) if j < 15 else Vector2(rand_range(-2500, 2800), rand_range(-3500, 2200))
        a.add_child(creer_humain(Color(0.18, 0.75, 0.38)))
        var col = CollisionShape2D.new()
        var sh = CircleShape2D.new()
        sh.radius = 15.0
        col.shape = sh
        a.add_child(col)
        a.set_meta("recrute", false)
        a.set_meta("cd", 0.0)
        a.set_meta("dir", Vector2(1, 0))
        add_child(a)
        allies.append(a)

func _physics_process(_delta):
    for a in allies:
        if !a.get_meta("recrute"):
            var dir = a.get_meta("dir")
            if randf() < 0.02:
                dir = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized()
                a.set_meta("dir", dir)
            a.look_at(a.position + dir)
            a.move_and_slide(dir * 95.0)

func spawn_ennemi(pos_joueur : Vector2, vague : int):
    var en = KinematicBody2D.new()
    var ang = rand_range(0, TAU)
    en.position = pos_joueur + Vector2(cos(ang), sin(ang)) * 900.0
    en.add_child(creer_humain(Color(0.88, 0.16, 0.16)))
    var col = CollisionShape2D.new()
    var sh = CircleShape2D.new()
    sh.radius = 15.0
    col.shape = sh
    en.add_child(col)
    en.set_meta("hp", 65 + vague * 15)
    en.set_meta("cd", 0.0)
    en.set_meta("arme", randf() < 0.45)
    add_child(en)
    ennemis.append(en)
