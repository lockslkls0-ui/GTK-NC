extends Node2D

var argent := 2500
var explosifs := 2
var coffre_pose := false
var coffre_pos := Vector2.ZERO
var coffre_bois := 0
var coffre_metal := 0
var coffre_balles := 0
var bombes_actives := []

func poser_coffre_qg(pos : Vector2) -> String:
    if coffre_pose:
        coffre_pos = pos + Vector2(45, 0)
        get_child(0).position = coffre_pos
        return "📦 Coffre de stockage du QG déplacé ici ! ([O] Déposer/Retirer)"
    coffre_pose = true
    coffre_pos = pos + Vector2(45, 0)
    var enceinte = Polygon2D.new(); enceinte.position = coffre_pos; enceinte.polygon = PoolVector2Array([Vector2(-140,-110), Vector2(140,-110), Vector2(140,110), Vector2(-140,110)]); enceinte.color = Color(0.28, 0.26, 0.24, 0.75); enceinte.z_index = 3; add_child(enceinte)
    var feu = Polygon2D.new(); feu.position = coffre_pos + Vector2(-60, 0); feu.polygon = PoolVector2Array([Vector2(-14,-14), Vector2(14,-14), Vector2(14,14), Vector2(-14,14)]); feu.color = Color(1.0, 0.55, 0.1); feu.z_index = 5; add_child(feu)
    var box = Polygon2D.new()
    box.position = coffre_pos
    box.polygon = PoolVector2Array([Vector2(-24,-18), Vector2(24,-18), Vector2(24,18), Vector2(-24,18)])
    box.color = Color(0.55, 0.32, 0.12)
    box.z_index = 5
    add_child(box)
    return "🏠 QG & Coffre de stockage installés ! ([O] Gérer le coffre | [P] Boutique)"

func poser_explosif(pos : Vector2) -> String:
    if explosifs <= 0:
        return "❌ Plus d'explosif artisanal ! Achètes-en au Shop [P] (1200 F)."
    explosifs -= 1
    var b = Polygon2D.new()
    b.position = pos
    b.polygon = PoolVector2Array([Vector2(-10,-10), Vector2(10,-10), Vector2(10,10), Vector2(-10,10)])
    b.color = Color(1.0, 0.25, 0.1)
    b.z_index = 7
    b.set_meta("timer", 2.2)
    add_child(b)
    bombes_actives.append(b)
    return "💣 Explosif artisanal amorcé (explosion dans 2.2s) !"

func maj_bombes(delta : float, ennemis : Array, joueur : KinematicBody2D) -> String:
    var msg := ""
    for i in range(bombes_actives.size() - 1, -1, -1):
        var b = bombes_actives[i]
        var t = b.get_meta("timer") - delta
        b.set_meta("timer", t)
        if t <= 0.0:
            var bp = b.position
            for j in range(ennemis.size() - 1, -1, -1):
                if ennemis[j].position.distance_to(bp) < 280.0:
                    ennemis[j].queue_free()
                    ennemis.remove(j)
                    argent += 250
            if joueur.position.distance_to(bp) < 110.0:
                joueur.pv = max(0.0, joueur.pv - 25.0)
            b.queue_free()
            bombes_actives.remove(i)
            msg = "💥 BOUM ! Explosif artisanal détoné (+250 F par cible éliminée) !"
    return msg
