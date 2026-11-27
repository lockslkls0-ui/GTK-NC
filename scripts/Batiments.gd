extends Node2D

var interieur_actif := false
var sur_toit := false
var pos_rue := Vector2.ZERO
var salle : Node2D = null
var badge_toit : Polygon2D = null

func monter_echelle(joueur : KinematicBody2D) -> String:
    sur_toit = not sur_toit
    if sur_toit:
        joueur.z_index = 12
        joueur.scale = Vector2(1.35, 1.35)
        joueur.cam.zoom = Vector2(1.25, 1.25)
        return "🪜 SUR LE TOIT ! Invulnérable au corps-à-corps + vue longue portée ([L] descendre)"
    else:
        joueur.z_index = 5
        joueur.scale = Vector2(1.0, 1.0)
        joueur.cam.zoom = Vector2(0.85, 0.85)
        return "🪜 Redescendu dans la rue."

func basculer(joueur : KinematicBody2D) -> String:
    if sur_toit: return "❌ Descends d'abord du toit [L]."
    if interieur_actif:
        interieur_actif = false
        if salle != null: salle.queue_free(); salle = null
        joueur.position = pos_rue
        return "🚪 Ressorti dans la rue."
    interieur_actif = true
    pos_rue = joueur.position
    salle = Polygon2D.new(); salle.position = Vector2(9500, 9500); salle.z_index = 8
    add_child(salle)
    joueur.position = Vector2(9500, 9620)
    return "🏠 INTÉRIEUR DU BÂTIMENT (Lit + Établi) — [E] Fouiller | [V] Sortir"
