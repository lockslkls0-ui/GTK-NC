extends Node2D

var feux_camp := []
var temps := 0.0

func _ready():
    z_index = 18
    var mat = CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = mat

func allumer_feu(pos : Vector2):
    feux_camp.append({"pos": pos, "vie": 240.0})
    update()

func _process(delta):
    temps += delta
    for i in range(feux_camp.size() - 1, -1, -1):
        feux_camp[i]["vie"] -= delta
        if feux_camp[i]["vie"] <= 0.0:
            feux_camp.remove(i)
    var m = get_parent()
    if m != null and (feux_camp.size() > 0 or m.est_nuit):
        update()

func _draw():
    var m = get_parent()
    if m == null: return
    var j = m.joueur
    var carte = m.carte
    var centre : Vector2 = j.position if j != null else Vector2.ZERO
    var nuit : bool = m.est_nuit

    # 1. Feux de camp allumés au briquet [K] (brillent de jour comme de nuit)
    for f in feux_camp:
        var fp : Vector2 = f["pos"]
        var pulse := 1.0 + 0.08 * sin(temps * 11.0 + fp.x * 0.01)
        draw_circle(fp, 240.0 * pulse, Color(0.55, 0.26, 0.06, 0.22))
        draw_circle(fp, 125.0 * pulse, Color(0.85, 0.42, 0.10, 0.34))
        draw_circle(fp, 48.0 * pulse, Color(1.0, 0.68, 0.20, 0.55))
        draw_circle(fp + Vector2(0, -4), 14.0 * pulse, Color(1.0, 0.88, 0.35, 0.90))
        draw_circle(fp + Vector2(2, -9), 7.0 * pulse, Color(1.0, 0.35, 0.08, 0.95))

    if not nuit or carte == null:
        return

    # 2. Lampadaires allumés en ville le long des routes autour du joueur
    var col_halo_lamp := Color(0.75, 0.58, 0.24, 0.26)
    var col_coeur_lamp := Color(1.0, 0.88, 0.52, 0.85)
    var ir := 0
    for r in carte.routes_locales:
        if ir % 2 == 0:
            var ar := Array(r)
            var pa : Vector2 = ar.pop_front()
            if pa.distance_to(centre) < 2800.0:
                draw_circle(pa, 95.0, col_halo_lamp)
                draw_circle(pa, 9.0, col_coeur_lamp)
        ir += 1
    var irn := 0
    for rn in carte.routes_nationales:
        if irn % 2 == 0:
            var arn := Array(rn)
            var pan : Vector2 = arn.pop_front()
            if pan.distance_to(centre) < 3200.0:
                draw_circle(pan, 115.0, col_halo_lamp)
                draw_circle(pan, 11.0, col_coeur_lamp)
        irn += 1

    # 3. Maisons & vérandas illuminées chez les habitants la nuit
    var col_maison_halo := Color(0.72, 0.48, 0.18, 0.22)
    var col_fenetre := Color(1.0, 0.84, 0.38, 0.88)
    var ib := 0
    for rb in carte.tous_bats:
        if ib % 3 != 1:
            var ab := Array(rb)
            var ctr : Vector2 = ab.pop_front()
            if ctr.distance_to(centre) < 3000.0:
                var dem : Vector2 = ab.pop_front()
                draw_circle(ctr, max(dem.x, dem.y) * 2.2 + 24.0, col_maison_halo)
                draw_rect(Rect2(ctr - Vector2(dem.x * 0.45, dem.y * 0.35), Vector2(max(6.0, dem.x * 0.4), max(5.0, dem.y * 0.35))), col_fenetre)
        ib += 1
