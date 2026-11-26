extends Node2D

var liste_structures := []

func poser_structure(pos : Vector2, pos_joueur : Vector2, type_outil : int):
    var bar = StaticBody2D.new()
    bar.position = pos
    bar.rotation = (pos - pos_joueur).angle() + PI / 2.0
    var coul = Color(0.82, 0.52, 0.18)
    var hp = 100
    if type_outil == 2:
        coul = Color(0.45, 0.52, 0.60)
        hp = 260
    elif type_outil == 3:
        coul = Color(0.95, 0.90, 0.35)
        hp = 80
        var halo = Polygon2D.new()
        halo.polygon = PoolVector2Array([Vector2(-190,-190), Vector2(190,-190), Vector2(190,190), Vector2(-190,190)])
        halo.color = Color(1.0, 0.95, 0.6, 0.18)
        bar.add_child(halo)
    var vis = Polygon2D.new()
    vis.polygon = PoolVector2Array([Vector2(-52,-13), Vector2(52,-13), Vector2(52,13), Vector2(-52,13)])
    vis.color = coul
    bar.add_child(vis)
    var col = CollisionShape2D.new()
    var sh = RectangleShape2D.new()
    sh.extents = Vector2(52, 13)
    col.shape = sh
    bar.add_child(col)
    bar.set_meta("hp", hp)
    add_child(bar)
    liste_structures.append(bar)
