extends Node2D

var _t_vague := 28.0
var _t_draw := 0.0
var autos_convoi := Dictionary()

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo and event.scancode == KEY_G:
        var m = get_parent()
        if m == null or m.get("joueur") == null or m.get("pop") == null: return
        var pj : Vector2 = m.joueur.position
        for a in m.pop.allies:
            if is_instance_valid(a) and not a.get_meta("recrute") and a.position.distance_to(pj) < 420.0:
                a.set_meta("recrute", true)
                if a.has_meta("cible_feu"): a.remove_meta("cible_feu")
                if m.get("audio") != null: m.audio.p_ok.play()
                m.hud.msg_label.text = "🤝 Survivant recruté ! Il te suit, combat et montera en convoi [F]."
                get_tree().set_input_as_handled(); return

func _process(delta):
    var m = get_parent()
    if m == null or m.get("joueur") == null or m.get("pop") == null: return
    var j = m.joueur; var pj : Vector2 = j.position
    _t_vague += delta
    if _t_vague >= 35.0:
        _t_vague = 0.0
        var nb_en : int = clamp(2 + m.vague, 3, 6)
        for _i in range(nb_en): m.pop.spawn_ennemi(pj, m.vague)
        m.hud.msg_label.text = "⚠️ ALERTE ! " + str(nb_en) + " attaquants en noir foncent sur toi !"
    var pl_lib : int = int(j.vehicule_ref.get_meta("places")) - 1 if (j.en_vehicule and j.vehicule_ref != null and j.vehicule_ref.has_meta("places")) else 0
    var idx_c := 0
    for a in m.pop.allies:
        if not is_instance_valid(a) or not a.get_meta("recrute"): continue
        if a.has_meta("cible_feu"): a.remove_meta("cible_feu")
        var id_a : int = a.get_instance_id()
        if j.en_vehicule and j.vehicule_ref != null:
            if pl_lib > 0:
                pl_lib -= 1; a.visible = false; a.position = pj
            else:
                a.visible = true
                if not autos_convoi.has(id_a) or not is_instance_valid(autos_convoi[id_a]):
                    m.veh.ajouter_veh("4x4 Convoi Clan", 4, 740.0, Color(0.20, 0.55, 0.35), 44, 22, a.position)
                    autos_convoi[id_a] = m.veh.vehicules.back()
                var vc = autos_convoi[id_a]; idx_c += 1
                var cib : Vector2 = pj - Vector2(cos(j.vehicule_ref.rotation), sin(j.vehicule_ref.rotation)) * (135.0 * float(idx_c))
                if vc.position.distance_to(cib) > 75.0:
                    var dc : Vector2 = (cib - vc.position).normalized()
                    vc.rotation = lerp_angle(vc.rotation, dc.angle(), 6.0 * delta); vc.position += dc * 480.0 * delta
                a.position = vc.position
        else:
            a.visible = true
            if autos_convoi.has(id_a): autos_convoi.erase(id_a)
            if a.position.distance_to(pj) > 105.0:
                a.look_at(pj); a.move_and_slide((pj - a.position).normalized() * 360.0)
    _combat_recrues_et_barres(m, j, delta)
    _ia_ennemis(m, j, delta)
    _t_draw += delta
    if _t_draw >= 0.14:
        _t_draw = 0.0
        if m.pop.ennemis.size() > 0: m.pop.update()

func _combat_recrues_et_barres(m, j, delta):
    for a in m.pop.allies:
        if is_instance_valid(a) and a.get_meta("recrute") and a.visible:
            var cd_r : float = float(a.get_meta("cd")) - delta
            a.set_meta("cd", cd_r)
            if cd_r <= 0.0:
                for en in m.pop.ennemis:
                    if is_instance_valid(en) and en.position.distance_to(a.position) < 520.0:
                        a.set_meta("cd", 0.55); a.look_at(en.position)
                        m.armes.creer_balle(a.position, (en.position - a.position).normalized(), 1.2, 32, Color(0.3, 1.0, 0.5), m, m.projectiles)
                        break

func _ia_ennemis(m, j, delta):
    var pj : Vector2 = j.position
    for i in range(m.pop.ennemis.size() - 1, -1, -1):
        var en = m.pop.ennemis[i]
        if not is_instance_valid(en):
            m.pop.ennemis.remove(i); continue
        if float(en.get_meta("hp")) <= 0.0:
            en.queue_free(); m.pop.ennemis.remove(i); m.gagner_xp(25.0, "Attaquant neutralisé"); continue
        var d : float = en.position.distance_to(pj)
        var dir : Vector2 = (pj - en.position).normalized()
        en.look_at(pj)
        if d > 42.0:
            en.move_and_slide(dir * (230.0 + float(m.vague) * 12.0))
        var cd : float = float(en.get_meta("cd")) - delta
        if d <= 48.0 and cd <= 0.0:
            en.set_meta("cd", 0.85)
            _infliger_degats(m, j, 14.0)
        elif d < 520.0 and cd <= 0.0 and en.get_meta("arme"):
            en.set_meta("cd", 1.35)
            m.armes.creer_balle(en.position + dir * 22.0, dir, 1.3, 14, Color(1.0, 0.2, 0.2), m, m.projectiles)
            m.projectiles.back().set_meta("ennemi", true)
        else:
            en.set_meta("cd", cd)

func _infliger_degats(m, j, deg : float):
    if j.en_vehicule and j.vehicule_ref != null:
        var pv_v : float = float(j.vehicule_ref.get_meta("pv_veh")) if j.vehicule_ref.has_meta("pv_veh") else 100.0
        j.vehicule_ref.set_meta("pv_veh", max(0.0, pv_v - deg))
    else:
        if m.armure > 0.0:
            var abs_a : float = min(m.armure, deg * 0.7)
            m.armure -= abs_a; deg -= abs_a
        j.pv = max(0.0, j.pv - deg)
