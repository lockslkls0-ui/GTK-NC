extends Node2D

var arme_idx := 0
var noms := ["Pistolet 9mm", "Fusil à Pompe", "Fusil d'Assaut", "Machette", "Sniper Lunette"]
var chargeurs := Array()
var max_charg := Array()
var reserve := 180
var cooldown := 0.0
var mode_lunette := false

func _ready():
    chargeurs.append(15); max_charg.append(15)
    chargeurs.append(6); max_charg.append(6)
    chargeurs.append(30); max_charg.append(30)
    chargeurs.append(1); max_charg.append(1)
    chargeurs.append(5); max_charg.append(5)

func changer_arme() -> String:
    arme_idx = (arme_idx + 1) % 5
    if arme_idx != 4:
        mode_lunette = false
    return "🔫 Arme équipée : " + noms[arme_idx]

func recharger() -> String:
    if arme_idx == 3:
        return "🔪 La machette n'a pas besoin de balles !"
    var manque = max_charg[arme_idx] - chargeurs[arme_idx]
    if manque <= 0 or reserve <= 0:
        return "❌ Rechargement impossible (Réserve: " + str(reserve) + ")."
    var pris = min(manque, reserve)
    chargeurs[arme_idx] += pris
    reserve -= pris
    return "🔄 " + noms[arme_idx] + " rechargé !"

func tirer(origine : Vector2, dir : Vector2, parent_node : Node2D, liste_proj : Array) -> String:
    if arme_idx == 3:
        cooldown = 0.35
        creer_balle(origine + dir * 28.0, dir, 0.12, 55, Color(0.9, 0.95, 1.0), parent_node, liste_proj)
        return ""
    if chargeurs[arme_idx] <= 0:
        return "🔫 Chargeur vide ! Appuie sur [R] pour recharger !"
    chargeurs[arme_idx] -= 1
    if arme_idx == 0:
        cooldown = 0.22
        creer_balle(origine, dir, 1.2, 35, Color(1.0, 0.9, 0.2), parent_node, liste_proj)
    elif arme_idx == 1:
        cooldown = 0.65
        for a in [-0.22, -0.11, 0.0, 0.11, 0.22]:
            creer_balle(origine, dir.rotated(a), 0.45, 28, Color(1.0, 0.65, 0.15), parent_node, liste_proj)
    elif arme_idx == 2:
        cooldown = 0.11
        creer_balle(origine, dir.rotated(rand_range(-0.05, 0.05)), 1.3, 28, Color(1.0, 0.95, 0.3), parent_node, liste_proj)
    elif arme_idx == 4:
        cooldown = 0.90
        creer_balle(origine, dir, 2.2, 140, Color(0.2, 0.95, 1.0), parent_node, liste_proj)
    return ""

func creer_balle(pos : Vector2, dir : Vector2, vie : float, degats : int, coul : Color, parent_node : Node2D, liste_proj : Array):
    var p = Polygon2D.new()
    p.polygon = PoolVector2Array([Vector2(-45,-4), Vector2(50,-4), Vector2(50,4), Vector2(-45,4)])
    p.color = coul
    p.position = pos
    p.rotation = dir.angle()
    p.z_index = 20
    p.set_meta("dir", dir)
    p.set_meta("vie", vie)
    p.set_meta("degats", degats)
    parent_node.add_child(p)
    liste_proj.append(p)
