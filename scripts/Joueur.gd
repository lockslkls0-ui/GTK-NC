extends KinematicBody2D
func charger_tex(chemin : String) -> ImageTexture:
    var img = Image.new()
    if img.load(chemin) != OK: return null
    var tex = ImageTexture.new()
    tex.create_from_image(img)
    return tex

var corps_visuel : Node2D
var lampe : Polygon2D
var cam : Camera2D
var speed := 340.0
var pv := 100.0
var pv_max := 100.0
var energie := 100.0
var energie_max := 100.0
var en_vehicule := false
var vehicule_ref : Node2D = null

func _ready():
    lampe = Polygon2D.new()
    lampe.polygon = PoolVector2Array([Vector2(14,-8), Vector2(440,-160), Vector2(440,160), Vector2(14,8)])
    lampe.color = Color(1.0, 0.95, 0.65, 0.26)
    lampe.visible = false
    add_child(lampe)
    corps_visuel = Node2D.new()
    var veste = Polygon2D.new()
    veste.polygon = PoolVector2Array([Vector2(-10,-18), Vector2(10,-18), Vector2(12,18), Vector2(-10,18)])
    veste.color = Color(0.18, 0.45, 0.78)
    corps_visuel.add_child(veste)
    var tete = Polygon2D.new()
    tete.polygon = PoolVector2Array([Vector2(-8,-9), Vector2(10,-9), Vector2(10,9), Vector2(-8,9)])
    tete.color = Color(0.92, 0.76, 0.62)
    corps_visuel.add_child(tete)
    var tj = charger_tex("res://assets/joueur.png")
    if tj != null:
        var sp_j = Sprite.new(); sp_j.texture = tj; corps_visuel.add_child(sp_j)
    add_child(corps_visuel)
    var col = CollisionShape2D.new()
    var sh = CircleShape2D.new()
    sh.radius = 16.0
    col.shape = sh
    add_child(col)
    cam = Camera2D.new()
    cam.current = true
    cam.zoom = Vector2(0.85, 0.85)
    add_child(cam)

func _physics_process(delta):
    if pv <= 0:
        return
    if not en_vehicule:
        corps_visuel.look_at(get_global_mouse_position())
        lampe.look_at(get_global_mouse_position())
    var dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir.x += 1
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q): dir.x -= 1
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir.y += 1
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z): dir.y -= 1
    if en_vehicule and vehicule_ref != null:
        var v_act = vehicule_ref.get_meta("vit")
        if dir.length() > 0 and v_act > 0.0:
            vehicule_ref.rotation = lerp_angle(vehicule_ref.rotation, dir.angle(), 7.0 * delta)
            move_and_slide(Vector2(cos(vehicule_ref.rotation), sin(vehicule_ref.rotation)) * v_act)
            vehicule_ref.position = position
    elif dir.length() > 0:
        var mult = 1.65 if (Input.is_key_pressed(KEY_SHIFT) and energie > 5.0) else 1.0
        if mult > 1.0: energie = max(0.0, energie - 28.0 * delta)
        else: energie = min(energie_max, energie + 15.0 * delta)
        move_and_slide(dir.normalized() * speed * mult)
