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
var _cd_sol := 0.0
var _mult_sol := 1.0
var pv := 100.0
var pv_max := 100.0
var energie := 100.0
var energie_max := 100.0
var en_vehicule := false
var vehicule_ref : Node2D = null

func _ready():
    lampe = Polygon2D.new()
    lampe.visible = false
    add_child(lampe)
    corps_visuel = Polygon2D.new()
    var veste = Polygon2D.new()
    corps_visuel.add_child(veste)
    var tete = Polygon2D.new()
    corps_visuel.add_child(tete)
    var bras := Polygon2D.new(); bras.polygon = PoolVector2Array([Vector2(-6, -17), Vector2(10, -17), Vector2(10, 17), Vector2(-6, 17)]); bras.color = Color(0.28, 0.16, 0.09); corps_visuel.add_child(bras)
    veste.polygon = PoolVector2Array([Vector2(-7, -11), Vector2(7, -11), Vector2(8, 11), Vector2(-8, 11)])
    veste.color = Color(0.16, 0.58, 0.34)
    tete.polygon = PoolVector2Array([Vector2(-6, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-6, 7)])
    tete.position = Vector2(3, 0); tete.color = Color(0.30, 0.17, 0.10)
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

func _est_dans_eau(p : Vector2, carte) -> bool:
    for rv in carte.toutes_rivieres:
        var a := Array(rv)
        if a.size() >= 2 and a.pop_front().distance_squared_to(p) < 14400.0: return true
    for t in carte.tous_tris:
        var a := Array(t)
        if a.pop_front().distance_squared_to(p) < 2500000.0:
            var poly : PoolVector2Array = a.pop_front()
            if Geometry.is_point_in_polygon(p, poly): return false
    return true

func _sur_route(p : Vector2, carte) -> bool:
    for r in carte.routes_nationales:
        var a := Array(r)
        if a.size() >= 2 and a.pop_front().distance_squared_to(p) < 12100.0: return true
    for r2 in carte.routes_locales:
        var a2 := Array(r2)
        if a2.size() >= 2 and a2.pop_front().distance_squared_to(p) < 12100.0: return true
    return false

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
            var carte = get_parent().get("carte")
            var nom_v : String = str(vehicule_ref.get_meta("nom")) if vehicule_ref.has_meta("nom") else ""
            var est_bat := ("Bateau" in nom_v or "Vedette" in nom_v)
            var fwd := Vector2(cos(vehicule_ref.rotation), sin(vehicule_ref.rotation))
            var v_eff : float = v_act
            _cd_sol -= delta
            if _cd_sol <= 0.0 and carte != null:
                _cd_sol = 0.22
                if est_bat: _mult_sol = 1.0 if _est_dans_eau(position + fwd * 28.0, carte) else 0.0
                else: _mult_sol = 1.0 if _sur_route(position, carte) else 0.50
            v_eff = v_act * _mult_sol
            move_and_slide(fwd * v_eff)
            vehicule_ref.position = position
    elif dir.length() > 0:
        var mult = 1.65 if (Input.is_key_pressed(KEY_SHIFT) and energie > 5.0) else 1.0
        if mult > 1.0: energie = max(0.0, energie - 28.0 * delta)
        else: energie = min(energie_max, energie + 15.0 * delta)
        move_and_slide(dir.normalized() * speed * mult)
