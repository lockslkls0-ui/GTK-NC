extends Node

static func traiter(m, delta : float):
    for i in range(m.projectiles.size() - 1, -1, -1):
        var p = m.projectiles[i]; p.position += p.get_meta("dir") * 680.0 * delta
        var v : float = p.get_meta("vie") - delta; p.set_meta("vie", v); var hit := false
        var msg_e : String = m.veh.verifier_explosion_pompe(p.position, m.pop.ennemis, m.joueur)
        if msg_e != "": m.hud.msg_label.text = msg_e; m.audio.p_boom.play(); hit = true
        if p.color == Color(1.0, 0.2, 0.2) and p.position.distance_to(m.joueur.position) < 26.0:
            hit = true
            if m.joueur.en_vehicule and m.joueur.vehicule_ref != null:
                if not m.joueur.vehicule_ref.has_meta("pv_veh"): m.joueur.vehicule_ref.set_meta("pv_veh", 100.0)
                var pv_v : float = max(0.0, m.joueur.vehicule_ref.get_meta("pv_veh") - 12.0)
                m.joueur.vehicule_ref.set_meta("pv_veh", pv_v)
                m.joueur.vehicule_ref.set_meta("essence", max(0.0, m.joueur.vehicule_ref.get_meta("essence") - 5.0))
                m.hud.msg_label.text = "💥 Véhicule touché ! Vie véhicule : " + str(int(pv_v)) + "%"
                if pv_v <= 0.0:
                    m.joueur.en_vehicule = false; m.joueur.vehicule_ref = null
                    m.hud.msg_label.text = "🔥 Véhicule hors service !"
            else:
                var deg : float = p.get_meta("degats")
                if m.armure > 0.0:
                    var abs_a : float = min(m.armure, deg * 0.7); m.armure -= abs_a; deg -= abs_a
                m.joueur.pv = max(0.0, m.joueur.pv - deg)
        for j in range(m.pop.ennemis.size() - 1, -1, -1):
            var en = m.pop.ennemis[j]
            if p.position.distance_to(en.position) < 42.0:
                var hp : float = en.get_meta("hp") - p.get_meta("degats"); en.set_meta("hp", hp); hit = true; en.modulate = Color(2.5, 0.5, 0.5)
                if hp <= 0.0:
                    en.queue_free(); m.pop.ennemis.remove(j); m.bois += 6; m.metal += 3; m.armes.reserve += 5; m.gagner_xp(25.0, "Cible neutralisée")
                break
        if v <= 0.0 or hit: p.queue_free(); m.projectiles.remove(i)
