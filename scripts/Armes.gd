extends Node2D

var arme_idx := 0
var noms := ["Pistolet 9mm", "Machette", "Fusil à Pompe", "Carabine Brousse", "Fusil d'Assaut", "Sniper Lunette", "Lance-Grenades"]
var debloquees := Array()
var chargeurs := Array()
var max_charg := Array()
var reserve := 180
var cooldown := 0.0
var mode_lunette := false

func _ready():
    z_index = 20
    chargeurs.append(15); max_charg.append(15); debloquees.append(true)
    chargeurs.append(1); max_charg.append(1); debloquees.append(true)
    chargeurs.append(6); max_charg.append(6); debloquees.append(false)
    chargeurs.append(8); max_charg.append(8); debloquees.append(false)
    chargeurs.append(30); max_charg.append(30); debloquees.append(false)
    chargeurs.append(5); max_charg.append(5); debloquees.append(false)
    chargeurs.append(3); max_charg.append(3); debloquees.append(false)

func debloquer_prochaine_arme() -> String:
    for i in range(debloquees.size()):
        if not debloquees[i]:
            debloquees[i] = true; arme_idx = i; return noms[i]
    reserve += 60; return "+60 Munitions (Arsenal complet)"

func changer_arme() -> String:
    for _t in range(7):
        arme_idx = (arme_idx + 1) % 7
        if debloquees[arme_idx]: break
    if arme_idx != 4:
        mode_lunette = false
    return "🔫 Arme équipée : " + noms[arme_idx]

func recharger() -> String:
    if arme_idx == 1:
        return "🔪 La machette n'a pas besoin de balles !"
    var manque = max_charg[arme_idx] - chargeurs[arme_idx]
    if manque <= 0 or reserve <= 0:
        return "❌ Rechargement impossible (Réserve: " + str(reserve) + ")."
    var pris = min(manque, reserve)
    chargeurs[arme_idx] += pris
    reserve -= pris
    return "🔄 " + noms[arme_idx] + " rechargé !"

func tirer(origine : Vector2, dir : Vector2, parent_node : Node2D, liste_proj : Array) -> String:
    if arme_idx == 1:
        cooldown = 0.35
        creer_balle(origine + dir * 28.0, dir, 0.12, 55, Color(0.9, 0.95, 1.0), parent_node, liste_proj)
        return ""
    if chargeurs[arme_idx] <= 0:
        return "🔫 Chargeur vide ! Appuie sur [R] pour recharger !"
    chargeurs[arme_idx] -= 1
    if arme_idx == 0:
        cooldown = 0.22
        creer_balle(origine, dir, 1.2, 35, Color(1.0, 0.9, 0.2), parent_node, liste_proj)
    elif arme_idx == 3 or arme_idx == 4:
        cooldown = 0.65
        for a in [-0.22, -0.11, 0.0, 0.11, 0.22]:
            creer_balle(origine, dir.rotated(a), 0.45, 28, Color(1.0, 0.65, 0.15), parent_node, liste_proj)
    elif arme_idx == 3 or arme_idx == 4:
        cooldown = 0.11
        creer_balle(origine, dir.rotated(rand_range(-0.05, 0.05)), 1.3, 28, Color(1.0, 0.95, 0.3), parent_node, liste_proj)
    elif arme_idx == 5 or arme_idx == 6:
        cooldown = 0.90
        creer_balle(origine, dir, 2.2, 140, Color(0.2, 0.95, 1.0), parent_node, liste_proj)
    return ""

func creer_balle(pos : Vector2, dir : Vector2, vie : float, degats : int, coul : Color, parent_node : Node2D, liste_proj : Array):
    var p = Polygon2D.new()
    p.polygon = PoolVector2Array([Vector2(-10, -2.5), Vector2(12, -2.5), Vector2(12, 2.5), Vector2(-10, 2.5)])
    p.color = coul
    p.position = pos
    p.rotation = dir.angle()
    p.z_index = 25
    var mat_b = CanvasItemMaterial.new(); mat_b.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; p.material = mat_b
    p.set_meta("dir", dir)
    p.set_meta("vie", vie)
    p.set_meta("degats", degats)
    parent_node.add_child(p)
    liste_proj.append(p)
